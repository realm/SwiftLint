//
//  ControlStatementRule.swift
//  SwiftLint
//
//  Created by Andrea Mazzini on 26/05/15.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public struct ControlStatementRule: ConfigProviderRule {

    public var config = SeverityConfig(.Warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "control_statement",
        name: "Control Statement",
        description: "if,for,while,do statements shouldn't wrap their conditionals in parentheses.",
        nonTriggeringExamples: [
            Trigger("if condition {\n"),
            Trigger("if (a, b) == (0, 1) {\n"),
            Trigger("if (a || b) && (c || d) {\n"),
            Trigger("if (min...max).contains(value) {\n"),
            Trigger("if renderGif(data) {\n"),
            Trigger("renderGif(data)\n"),
            Trigger("for item in collection {\n"),
            Trigger("for (key, value) in dictionary {\n"),
            Trigger("for (index, value) in enumerate(array) {\n"),
            Trigger("for var index = 0; index < 42; index++ {\n"),
            Trigger("guard condition else {\n"),
            Trigger("while condition {\n"),
            Trigger("} while condition {\n"),
            Trigger("do { ; } while condition {\n"),
            Trigger("switch foo {\n")
        ],
        triggeringExamples: [
            Trigger("↓if (condition) {\n"),
            Trigger("↓if(condition) {\n"),
            Trigger("↓if ((a || b) && (c || d)) {\n"),
            Trigger("↓if ((min...max).contains(value)) {\n"),
            Trigger("↓for (item in collection) {\n"),
            Trigger("↓for (var index = 0; index < 42; index++) {\n"),
            Trigger("↓for(item in collection) {\n"),
            Trigger("↓for(var index = 0; index < 42; index++) {\n"),
            Trigger("↓guard (condition) else {\n"),
            Trigger("↓while (condition) {\n"),
            Trigger("↓while(condition) {\n"),
            Trigger("} ↓while (condition) {\n"),
            Trigger("} ↓while(condition) {\n"),
            Trigger("do { ; } ↓while(condition) {\n"),
            Trigger("do { ; } ↓while (condition) {\n"),
            Trigger("↓switch (foo) {\n")
        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        let statements = ["if", "for", "guard", "switch", "while"]
        return statements.flatMap { statementKind -> [StyleViolation] in
            let pattern = statementKind == "guard"
                ? "\(statementKind)\\s*\\([^,{]*\\)\\s*else\\s*\\{"
                : "\(statementKind)\\s*\\([^,{]*\\)\\s*\\{"
            return file.matchPattern(pattern).flatMap { match, syntaxKinds in
                let matchString = file.contents.substring(match.location, length: match.length)
                if self.isFalsePositive(matchString, syntaxKind: syntaxKinds.first) {
                    return nil
                }
                return StyleViolation(ruleDescription: self.dynamicType.description,
                    severity: self.config.severity,
                    location: Location(file: file, characterOffset: match.location))
            }
        }

    }

    private func isFalsePositive(content: String, syntaxKind: SyntaxKind?) -> Bool {
        if syntaxKind != .Keyword {
            return true
        }

        guard let lastClosingParenthesePosition = content.lastIndexOf(")") else {
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
