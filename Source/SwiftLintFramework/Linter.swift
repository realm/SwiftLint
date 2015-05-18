//
//  Linter.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Foundation
import SwiftXPC
import SourceKittenFramework

public struct Linter {
    private let file: File
    private let structure: Structure

    public var styleViolations: [StyleViolation] {
        return file.astViolationsInDictionary(structure.dictionary) + file.stringViolations
    }

    /**
    Initialize a Linter by passing in a File.

    :param: file File to lint.
    */
    public init(file: File) {
        self.file = file
        structure = Structure(file: file)
    }
}
