import Foundation
import SourceKittenFramework
import SwiftSyntax

/// A specific location within a source file.
public struct Location: CustomStringConvertible, Comparable, Codable, Sendable {
    /// The file path on disk for this location.
    public let file: URL?
    /// The line offset in the file for this location. 1-indexed.
    public let line: Int?
    /// The character offset in the file for this location. 1-indexed.
    public let character: Int?

    /// A lossless printable description of this location.
    public var description: String {
        // Xcode likes warnings and errors in the following format:
        // {full_path_to_file}{:line}{:character}: {error,warning}: {content}
        let fileString = file?.path ?? "<nopath>"
        let lineString = ":\(line ?? 1)"
        let charString = ":\(character ?? 1)"
        return [fileString, lineString, charString].joined()
    }

    /// Creates a `Location` by specifying its properties directly.
    ///
    /// - parameter file:      The file path on disk for this location.
    /// - parameter line:      The line offset in the file for this location. 1-indexed.
    /// - parameter character: The character offset in the file for this location. 1-indexed.
    public init(file: URL?, line: Int? = nil, character: Int? = nil) {
        self.file = file
        self.line = line
        self.character = character
    }

    /// Creates a `Location` based on a `SwiftLintFile` and a byte-offset into the file.
    /// Fails if the specified offset was not a valid location in the file.
    ///
    /// - parameter file:   The file for this location.
    /// - parameter offset: The offset in bytes into the file for this location.
    public init(file: SwiftLintFile, byteOffset offset: ByteCount) {
        let lineAndCharacter = file.stringView.lineAndCharacter(forByteOffset: offset)
        self.init(
            file: file.path,
            line: lineAndCharacter?.line,
            character: lineAndCharacter?.character
        )
    }

    /// Creates a `Location` based on a `SwiftLintFile` and a SwiftSyntax `AbsolutePosition` into the file.
    /// Fails if the specified offset was not a valid location in the file.
    ///
    /// - parameter file:     The file for this location.
    /// - parameter position: The absolute position returned from SwiftSyntax.
    public init(file: SwiftLintFile, position: AbsolutePosition) {
        self.init(file: file, byteOffset: ByteCount(position.utf8Offset))
    }

    /// Creates a `Location` based on a `SwiftLintFile` and a UTF8 character-offset into the file.
    /// Fails if the specified offset was not a valid location in the file.
    ///
    /// - parameter file:   The file for this location.
    /// - parameter offset: The offset in UTF8 fragments into the file for this location.
    public init(file: SwiftLintFile, characterOffset offset: Int) {
        let lineAndCharacter = file.stringView.lineAndCharacter(forCharacterOffset: offset)
        self.init(
            file: file.path,
            line: lineAndCharacter?.line,
            character: lineAndCharacter?.character
        )
    }

    // MARK: Comparable

    public static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.file != rhs.file {
            return lhs.file?.path < rhs.file?.path
        }
        if lhs.line != rhs.line {
            return lhs.line < rhs.line
        }
        return lhs.character < rhs.character
    }
}

private extension Optional where Wrapped: Comparable {
    static func < (lhs: Optional, rhs: Optional) -> Bool {
        switch (lhs, rhs) {
        case let (lhs?, rhs?):
            return lhs < rhs
        case (nil, _?):
            return true
        default:
            return false
        }
    }
}
