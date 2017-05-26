//
//  ControlStatementRule.swift
//  SwiftLint
//
//  Created by Andrea Mazzini on 26/05/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public struct ControlStatementRule: ConfigurationProviderRule {

    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "control_statement",
        name: "Control Statement",
        description: "if,for,while,do statements shouldn't wrap their conditionals in parentheses.",
        nonTriggeringExamples: [
            "if condition {\n",
            "if (a, b) == (0, 1) {\n",
            "if (a || b) && (c || d) {\n",
            "if (min...max).contains(value) {\n",
            "if renderGif(data) {\n",
            "renderGif(data)\n",
            "for item in collection {\n",
            "for (key, value) in dictionary {\n",
            "for (index, value) in enumerate(array) {\n",
            "for var index = 0; index < 42; index++ {\n",
            "guard condition else {\n",
            "while condition {\n",
            "} while condition {\n",
            "do { ; } while condition {\n",
            "switch foo {\n"
        ],
        triggeringExamples: [
            "↓if (condition) {\n",
            "↓if(condition) {\n",
            "↓if ((a || b) && (c || d)) {\n",
            "↓if ((min...max).contains(value)) {\n",
            "↓for (item in collection) {\n",
            "↓for (var index = 0; index < 42; index++) {\n",
            "↓for(item in collection) {\n",
            "↓for(var index = 0; index < 42; index++) {\n",
            "↓guard (condition) else {\n",
            "↓while (condition) {\n",
            "↓while(condition) {\n",
            "} ↓while (condition) {\n",
            "} ↓while(condition) {\n",
            "do { ; } ↓while(condition) {\n",
            "do { ; } ↓while (condition) {\n",
            "↓switch (foo) {\n"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        let statements = ["if", "for", "guard", "switch", "while"]
        return statements.flatMap { statementKind -> [StyleViolation] in
            let pattern = statementKind == "guard"
                ? "\(statementKind)\\s*\\([^,{]*\\)\\s*else\\s*\\{"
                : "\(statementKind)\\s*\\([^,{]*\\)\\s*\\{"
            return file.match(pattern: pattern).flatMap { arg in
                let (match, syntaxKinds) = arg
                let matchString = file.contents.substring(from: match.location, length: match.length)
                if isFalsePositive(matchString, syntaxKind: syntaxKinds.first) {
                    return nil
                }
                return StyleViolation(ruleDescription: type(of: self).description,
                    severity: configuration.severity,
                    location: Location(file: file, characterOffset: match.location))
            }
        }

    }

    fileprivate func isFalsePositive(_ content: String, syntaxKind: SyntaxKind?) -> Bool {
        if syntaxKind != .keyword {
            return true
        }

        guard let lastClosingParenthesePosition = content.lastIndex(of: ")") else {
            return false
        }

        var depth = 0
        var index = 0
        for char in content.characters {
            if char == ")" {
                if index != lastClosingParenthesePosition && depth == 1 {
                    return true
                }
                depth -= 1
            } else if char == "(" {
                depth += 1
            }
            index += 1
        }
        return false
    }
}
