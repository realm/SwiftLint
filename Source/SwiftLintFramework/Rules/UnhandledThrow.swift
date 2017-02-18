//
//  UnhandledThrow.swift
//  SwiftLint
//
//  Created by Arthur Ariel Sabintsev on 2/16/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct UnhandledThrowRule: Rule, ConfigurationProviderRule {

    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "unhandled_throw",
        name: "Unhandled Throw",
        description: "When a throwing function does not explicitly handle a throw, the `throws` keyword can be removed.",
        nonTriggeringExamples: [
            "func f() throws",
            "func f() throws -> Any",
            "func f() throws {\n throw anException \n}",
            "func f() throws -> Any {\n throw anException \n}",
            "func f() throws {\n return try anException \n}",
            "func f() throws -> Any {\n return try anException \n}",
            "func f() throws {\n return try? anException \n}",
            "func f() throws -> Any {\n return try? anException \n}",
            "func f() throws {\n return try! anException \n}",
            "func f() throws { return try! anException }",
            "func f() throws -> Any {\n return try! anException \n}",
            "func f() throws {\n do {\n try b() \n} catch {\n throw b \n} \n}",
            "func f() throws -> Any {\n do {\n try b() \n} catch {\n throw anException \n} \n}",
            "func f() throws {\n do {\n return try b() \n} catch {\n throw b \n} \n}",
            "func f() throws -> Any {\n do {\n return try b() \n} catch {\n throw anException \n} \n}"
        ],
        triggeringExamples: [
            "func f() throws {}",
            "func f() throws { }",
            "func f() throws {\n}",
            "func f() throws {\n \n}",
            "func f() throws -> Any {}",
            "func f() throws -> Any { }",
            "func f() throws -> Any {\n}",
            "func f() throws -> Any {\n \n}",
            "func f() throws {\n var x = 0 \n}",
            "func f() throws -> Any {\n var x = 0 \n}",
            "func f() throws {\n do {\n try b() \n} catch {\n \n} \n}",
            "func f() throws -> Any{\n do {\n try b() \n} catch {\n \n} \n}"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        let pattern = "(func).+(throws)"

        let rule1 = "(func).+(throws)\\b$"
        let rule2 = "(func).+(throws)\\b.+[\\-\\>].+?\\b$"
        let rule3 = "(func).+(throws)\\b.+(throw)\\s\\S.+?$"
        let rule4 = "(func).+(throws)\\b.+(try).+[\\{].+(throw)\\s\\S.+?$"
        let rule5 = "(func).+(throws)\\b.+(return)\\s(try).+$"
        let excludingPattern = "(\(rule1)|\(rule2)|\(rule3)|\(rule4)|\(rule5))"

        let matches = file.match(pattern: pattern,
                                 excludingSyntaxKinds: SyntaxKind.commentAndStringKinds(),
                                 excludingPattern: excludingPattern)

        return matches.map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

}
