//
//  CustomRules.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 1/21/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework
import SwiftXPC

public struct CustomRules: ASTRule {

    public static let description = RuleDescription(
        identifier: "custom_rules",
        name: "Custom Rules",
        description: "Create custom rules by providing a regex string. " +
          "Optionally specify what syntax kinds to match against, the severity " +
          "level, and what message to display")

    public init() {}

    public func validateFile(file: File,
                             kind: SwiftDeclarationKind,
                             dictionary: XPCDictionary) -> [StyleViolation] {
        return []
    }
}
