//
//  UnhandledThrowRule.swift
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
        description: "The throwing function does not throw. The `throws` keyword can be removed.",
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
        let excludingPatterns = [
            "",
            ".+[\\-\\>].+?\\b",
            ".+(throw)\\s\\S.+?",
            ".+(try).+[\\{].+(throw)\\s\\S.+?",
            ".+(return)\\s(try).+"
        ]
        let excludingPattern = excludingPatterns.map({ "\(pattern)\\b\($0)$" })
                                                .joined(separator: "|")

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
