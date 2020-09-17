import Foundation
import SourceKittenFramework

/// A unit of Swift source code, either on disk or in memory.
public final class SwiftLintFile {
    let file: File
    let id: UUID

    /// Creates a `SwiftLintFile` with a SourceKitten `File`.
    ///
    /// - parameter file: A file from SourceKitten.
    public init(file: File) {
        self.file = file
        self.id = UUID()
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

    /// Returns whether or not the file contains any attributes that require the Foundation module.
    func containsAttributesRequiringFoundation() -> Bool {
        guard contents.contains("@objc") else {
            return false
        }

        func containsAttributesRequiringFoundation(dict: SourceKittenDictionary) -> Bool {
            let attributesRequiringFoundation = SwiftDeclarationAttributeKind.attributesRequiringFoundation
            if !attributesRequiringFoundation.isDisjoint(with: dict.enclosedSwiftAttributes) {
                return true
            } else {
                return dict.substructure.contains(where: containsAttributesRequiringFoundation)
            }
        }

        return containsAttributesRequiringFoundation(dict: structureDictionary)
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
