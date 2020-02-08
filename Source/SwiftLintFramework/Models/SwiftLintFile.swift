import Foundation
import SourceKittenFramework

/// A unit of Swift source code, either on disk or in memory.
public final class SwiftLintFile {
    private static var id = 0
    private static var lock = NSLock()

    private static func nextID () -> Int {
        lock.lock()
        defer { lock.unlock() }
        id += 1
        return id
    }

    let file: File
    let id: Int

    private let queue = DispatchQueue(label: "regexQueue")
    private var items: [RegexRequest] = []
    private var idx: Int = 0
    private let regexGroup = DispatchGroup()

    /// Creates a `SwiftLintFile` with a SourceKitten `File`.
    ///
    /// - parameter file: A file from SourceKitten.
    public init(file: File) {
        self.file = file
        self.id = SwiftLintFile.nextID()
    }

    /// Creates a `SwiftLintFile` by specifying its path on disk.
    /// Fails if the file does not exist.
    ///
    /// - parameter path: The path to a file on disk. Relative and absolute paths supported.
    public convenience init?(path: String) {
        guard let file = File(path: path) else { return nil }
        self.init(file: file)
    }

    /// Creates a `SwiftLintFile` by specifying its path on disk. Unlike the  `SwiftLintFile(path:)` initializer, this
    /// one does not read its contents immediately, but rather traps at runtime when attempting to access its contents.
    ///
    /// - parameter path: The path to a file on disk. Relative and absolute paths supported.
    public convenience init(pathDeferringReading path: String) {
        self.init(file: File(pathDeferringReading: path))
    }

    /// Creates a `SwiftLintFile` that is not backed by a file on disk by specifying its contents.
    ///
    /// - parameter contents: The contents of the file.
    public convenience init(contents: String) {
        self.init(file: File(contents: contents))
    }

    /// The path on disk for this file.
    public var path: String? {
        return file.path
    }

    /// The file's contents.
    public var contents: String {
        return file.contents
    }

    /// A string view into the contents of this file optimized for string manipulation operations.
    public var stringView: StringView {
        return file.stringView
    }

    /// The parsed lines for this file's contents.
    public var lines: [Line] {
        return file.lines
    }
}

// MARK: - Hashable Conformance

extension SwiftLintFile: Hashable {
    public static func == (lhs: SwiftLintFile, rhs: SwiftLintFile) -> Bool {
        return lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}



private struct RegexRequest {
    let id: Int
    let pattern: String
    let result: ([SwiftlintTextCheckingResult]) -> ()
}

struct SwiftlintTextCheckingResult {
    let offset: Int
    let ranges: [NSRange]
    let range: NSRange
    let numberOfRanges: Int
    init(original: NSTextCheckingResult) {
        self.offset = 0
        self.range = original.range
        self.numberOfRanges = original.numberOfRanges
        self.ranges = (0..<original.numberOfRanges).map { original.range(at: $0) }
    }
    init(original: NSTextCheckingResult, offset: Int, numberOfRanges: Int ) {
        self.offset = offset
        self.range = original.range
        self.numberOfRanges = numberOfRanges
        self.ranges = (0...numberOfRanges).map { original.range(at: $0 + offset) }
    }

    func range(at group: Int) -> NSRange {
        return ranges[group]
    }
}
extension SwiftLintFile {

    func matches2(pattern: String) -> [SwiftlintTextCheckingResult] {

        var res:[SwiftlintTextCheckingResult] = []
        let p: Int = queue.sync {
            self.idx += 1
            let id = self.idx
            items.append(RegexRequest(id: id, pattern: pattern, result: { res = $0 }))
            return id
        }
//        Thread.sleep(forTimeInterval: 0.1)
        queue.async {
            let lstId = self.items.last?.id
            guard lstId == p else { return }
             // process
            self.process(requests: self.items)
            self.items.removeAll()
            self.regexGroup.notify(queue: self.queue) { }
        }
        regexGroup.wait()
        return res
    }


    private func process(requests:[RegexRequest]) {
        // Gather requests
        let regexes = requests.map { regex($0.pattern) }
        let fullRegex = requests.map { "(\($0.pattern))" }.joined(separator: "|")
//        print("Fill REgex \(fullRegex)")

        // offsets
        var ofs = 1
        var offsets: [(Int, Int)] = []
        regexes.forEach {
            offsets.append((ofs, $0.numberOfCaptureGroups))
            ofs += $0.numberOfCaptureGroups + 1
        }

        let fullR = regex(fullRegex)

//        print("FullR: [\(requests.count)] [\(fullR.numberOfCaptureGroups)] \(fullR) ")

        assert(fullR.numberOfCaptureGroups == ofs - 1, "Total number of capture groups should be the same \(fullR.numberOfCaptureGroups) : \(requests.count) :\(ofs)")
        let allMatches = fullR.matches(in: stringView)

//        print("Total matches \(allMatches.count)")

        requests.enumerated().forEach { item in
            let r = allMatches.filter { $0.range(at: offsets[item.offset].0).length != NSNotFound }
                .map { SwiftlintTextCheckingResult(original: $0, offset: offsets[item.offset].0, numberOfRanges: offsets[item.offset].1)}
            item.element.result(r)
        }
    }
}
