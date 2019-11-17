import Foundation
import SourceKittenFramework

private struct TraversingInfo {
    let declarations: [(SwiftDeclarationKind, SourceKittenDictionary)]
    let expressions: [(SwiftExpressionKind, SourceKittenDictionary)]
}

public final class SwiftLintFile {
    private static var id = 0
    private static var lock = NSLock()

    private static func nextId () -> Int {
        lock.lock()
        defer { lock.unlock() }
        id += 1
        return id
    }

    let file: File
    let id: Int

    public init(file: File) {
        self.file = file
        self.id = SwiftLintFile.nextId()
    }

    public convenience init?(path: String) {
        guard let file = File(path: path) else { return nil }
        self.init(file: file)
    }

    public convenience init(pathDeferringReading path: String) {
        self.init(file: File(pathDeferringReading: path))
    }

    public convenience init(contents: String) {
        self.init(file: File(contents: contents))
    }

    public var path: String? {
        return file.path
    }

    public var contents: String {
        return file.contents
    }

    public var lines: [Line] {
        return file.lines
    }

    private lazy var traversingInfo: TraversingInfo = {
        return TraversingInfo(
            declarations: structureDictionary.traverseDepthFirst { dict in
                guard let kind = dict.declarationKind else { return nil }
                return [(kind, dict)]
            },
            expressions: structureDictionary.traverseDepthFirst { dict in
                guard let kind = dict.expressionKind else { return nil }
                return [(kind, dict)]
            })
    }()
}

extension SwiftLintFile {
    func traverseDeclarations<T>(_ block: (SwiftDeclarationKind, SourceKittenDictionary) -> [T]?) -> [T] {
        var result: [T] = []
        traversingInfo.declarations.forEach {
            guard let items = block($0.0, $0.1) else { return }
            result += items
        }
        return result
    }

    func traverseExpressions<T>(_ block: (SwiftExpressionKind, SourceKittenDictionary) -> [T]?) -> [T] {
        var result: [T] = []
        traversingInfo.expressions.forEach {
            guard let items = block($0.0, $0.1) else { return }
            result += items
        }
        return result
    }

}

extension SwiftLintFile: Hashable {
    public static func == (lhs: SwiftLintFile, rhs: SwiftLintFile) -> Bool {
        return lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
