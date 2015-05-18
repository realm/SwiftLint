//
//  ASTRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework
import SwiftXPC

protocol ASTRule: Rule {
    static func validateFile(file: File, dictionary: XPCDictionary) -> [StyleViolation]

    static func validateFile(file: File,
        kind: SwiftDeclarationKind,
        dictionary: XPCDictionary) -> [StyleViolation]
}
