import Foundation
import SourceKittenFramework

public struct Location: CustomStringConvertible, Comparable, Codable {
    public let file: String?
    public let line: Int?
    public let character: Int?
    public var description: String {
        // Xcode likes warnings and errors in the following format:
        // {full_path_to_file}{:line}{:character}: {error,warning}: {content}
        let fileString: String = file ?? "<nopath>"
        let lineString: String = ":\(line ?? 1)"
        let charString: String = ":\(character ?? 1)"
        return [fileString, lineString, charString].joined()
    }
    public var relativeFile: String? {
        return file?.replacingOccurrences(of: FileManager.default.currentDirectoryPath + "/", with: "")
    }

    public init(file: String?, line: Int? = nil, character: Int? = nil) {
        self.file = file
        self.line = line
        self.character = character
    }

    public init(file: SwiftLintFile, byteOffset offset: Int) {
        self.file = file.path
        if let lineAndCharacter = file.linesContainer.lineAndCharacter(forByteOffset: offset) {
            line = lineAndCharacter.line
            character = lineAndCharacter.character
        } else {
            line = nil
            character = nil
        }
    }

    public init(file: SwiftLintFile, characterOffset offset: Int) {
        self.file = file.path
        if let lineAndCharacter = file.linesContainer.lineAndCharacter(forCharacterOffset: offset) {
            line = lineAndCharacter.line
            character = lineAndCharacter.character
        } else {
            line = nil
            character = nil
        }
    }

    // MARK: Comparable

    public static func < (lhs: Location, rhs: Location) -> Bool {
        if lhs.file != rhs.file {
            return lhs.file < rhs.file
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
