//
//  UntypedErrorInCatchRule.swift
//  SwiftLint
//
//  Created by Daniel.Metzing on 17/02/18.
//  Copyright © 2018 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct UntypedErrorInCatchRule: OptInRule, ConfigurationProviderRule {

    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    private static let regularExpression =
        "catch" + // The catch keyword
        "(?:"   + // Start of the first non-capturing group
        "\\s*"  + // Zero or multiple whitespace character
        "\\("   + // The `(` character
        "?"     + // Zero or one occurrence of the previous character
        "\\s*"  + // Zero or multiple whitespace character
        "(?:"   + // Start of the alternative non-capturing group
        "let"   + // `let` keyword
        "|"     + // OR
        "var"   + // `var` keyword
        ")"     + // End of the alternative non-capturing group
        "\\s+"  + // At least one any type of whitespace character
        "\\w+"  + // At least one any type of word character
        "\\s*"  + // Zero or multiple whitespace character
        "\\)"   + // The `)` character
        "?"     + // Zero or one occurrence of the previous character
        ")"     + // End of the first non-capturing group
        "(?:"   + // Start of the second non-capturing group
        "\\s*"  + // Zero or unlimited any whitespace character
        ")"     + // End of the second non-capturing group
        "\\{"     // Start scope character

    public static let description = RuleDescription(
        identifier: "untyped_error_in_catch",
        name: "Untyped Error in Catch",
        description: "Catch statements should not declare error variables without type casting.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            "do {\n    try foo() \n} catch {}",
            "do {\n    try foo() \n} catch Error.invalidOperation {\n} catch {}",
            "do {\n    try foo() \n} catch let error as MyError {\n} catch {}",
            "do {\n    try foo() \n} catch var error as MyError {\n} catch {}"
        ],
        triggeringExamples: [
            "do {\n    try foo() \n} ↓catch var error {}",
            "do {\n    try foo() \n} ↓catch let error {}",
            "do {\n    try foo() \n} ↓catch let someError {}",
            "do {\n    try foo() \n} ↓catch var someError {}",
            "do {\n    try foo() \n} ↓catch let e {}",
            "do {\n    try foo() \n} ↓catch(let error) {}",
            "do {\n    try foo() \n} ↓catch (let error) {}"
        ])

    public func validate(file: File) -> [StyleViolation] {
        let matches = file.match(pattern: type(of: self).regularExpression,
                                 with: [.keyword, .keyword, .identifier])

        return matches.map {
            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: configuration.severity,
                                  location: Location(file: file, characterOffset: $0.location),
                                  reason: configuration.consoleDescription)
        }
    }
}
