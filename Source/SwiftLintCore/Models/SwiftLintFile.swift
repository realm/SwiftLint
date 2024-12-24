import Foundation
@preconcurrency import SourceKittenFramework

/// A unit of Swift source code, either on disk or in memory.
public final class SwiftLintFile: Sendable {
    /// The underlying SourceKitten file.
    public let file: File
    /// The associated unique identifier for this file.
    public let id: UUID
    /// Whether or not this is a file generated for testing purposes.
    public let isTestFile: Bool
    /// A file is virtual if it is not backed by a filesystem path.
    public let isVirtual: Bool

    /// Creates a `SwiftLintFile` with a SourceKitten `File`.
    ///
    /// - parameter file: A file from SourceKitten.
    /// - parameter isTestFile: Mark the file as being generated for testing purposes only.
    /// - parameter isVirtual: Mark the file as virtual (in-memory).
    public init(file: File, isTestFile: Bool = false, isVirtual: Bool = false) {
        self.file = file
        self.id = UUID()
        self.isTestFile = isTestFile
        self.isVirtual = isVirtual
    }

    /// Creates a `SwiftLintFile` by specifying its path on disk.
    /// Fails if the file does not exist.
    ///
    /// - parameter path: The path to a file on disk. Relative and absolute paths supported.
    /// - parameter isTestFile: Mark the file as being generated for testing purposes only.
    public convenience init?(path: String, isTestFile: Bool = false) {
        guard let file = File(path: path) else { return nil }
        self.init(file: file, isTestFile: isTestFile)
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
    /// - parameter isTestFile: Mark the file as being generated for testing purposes only.
    public convenience init(contents: String, isTestFile: Bool = false) {
        self.init(file: File(contents: contents), isTestFile: isTestFile, isVirtual: true)
    }

    /// The path on disk for this file.
    public var path: String? {
        file.path
    }

    /// The file's contents.
    public var contents: String {
        file.contents
    }

    /// A string view into the contents of this file optimized for string manipulation operations.
    public var stringView: StringView {
        file.stringView
    }

    /// The parsed lines for this file's contents.
    public var lines: [Line] {
        file.lines
    }
}

// MARK: - Hashable Conformance

extension SwiftLintFile: Equatable, Hashable {
    public static func == (lhs: SwiftLintFile, rhs: SwiftLintFile) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
