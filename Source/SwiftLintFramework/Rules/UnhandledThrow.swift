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
            "func f() throws {\n throw anError \n}\n",
            "func f() throws { throw anError }\n",
            "func f() throws -> Any {\n throw anError \n}\n",
            "func f() throws -> Any { throw anError }\n",
            "func f() throws {\n try anExpression \n}\n",
            "func f() throws { try anExpression }\n",
            "func f() throws -> Any {\n try anExpression \n}\n",
            "func f() throws -> Any { try anExpression }\n",
            "func f() throws {\n try? anExpression \n}\n",
            "func f() throws { try? anExpression }\n",
            "func f() throws -> Any {\n try? anExpression \n}\n",
            "func f() throws -> Any { try? anExpression }\n",
            "func f() throws {\n try! anExpression \n}\n",
            "func f() throws { try! anExpression }\n",
            "func f() throws -> Any {\n try! anExpression \n}\n",
            "func f() throws -> Any { try! anExpression }\n"
        ],
        triggeringExamples: [
            "func f() throws {}\n",
            "func f() throws { }\n",
            "func f() throws {\n}\n",
            "func f() throws {\n \n}\n",
            "func f() throws -> Any {}\n",
            "func f() throws -> Any { }\n",
            "func f() throws -> Any {\n}\n",
            "func f() throws -> Any {\n \n}\n",
            "func f() throws { var x = 0 }\n",
            "func f() throws {\n var x = 0 \n}\n",
            "func f() throws -> Any { var x = 0 }\n",
            "func f() throws -> Any {\n var x = 0 \n}\n"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        let pattern = "(func).+(throws).+"
        let excludingPattern = "(throw|try|try\\!|try\\?)\\s\\S"

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
