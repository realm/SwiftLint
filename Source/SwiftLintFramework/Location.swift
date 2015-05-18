//
//  Location.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public struct Location: Printable, Equatable {
    public let file: String?
    public let line: Int?
    public let character: Int?
    public var description: String {
        // Xcode likes warnings and errors in the following format:
        // {full_path_to_file}{:line}{:character}: {error,warning}: {content}
        return (file ?? "<nopath>") +
            (map(line, { ":\($0)" }) ?? "") +
            (map(character, { ":\($0)" }) ?? "")
    }

    public init(file: String?, line: Int? = nil, character: Int? = nil) {
        self.file = file
        self.line = line
        self.character = character
    }

    public init(file: File, offset: Int) {
        self.file = file.path
        if let lineAndCharacter = file.contents.lineAndCharacterForByteOffset(offset) {
            line = lineAndCharacter.line
            character = nil // FIXME: Use lineAndCharacter.character once it works.
        } else {
            line = nil
            character = nil
        }
    }
}

// MARK: Equatable

/**
Returns true if `lhs` Location is equal to `rhs` Location.

:param: lhs Location to compare to `rhs`.
:param: rhs Location to compare to `lhs`.

:returns: True if `lhs` Location is equal to `rhs` Location.
*/
public func ==(lhs: Location, rhs: Location) -> Bool {
    return lhs.file == rhs.file &&
        lhs.line == rhs.line &&
        lhs.character == rhs.character
}
