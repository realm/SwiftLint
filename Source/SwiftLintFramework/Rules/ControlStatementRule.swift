//
//  ControlStatementRule.swift
//  SwiftLint
//
//  Created by Andrea Mazzini on 26/05/15.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public struct ControlStatementRule: Rule {
    public init() {}

    public static let description = RuleDescription(
        identifier: "control_statement",
        name: "Control Statement",
        description: "if,for,while,do statements shouldn't wrap their conditionals in parentheses.",
        nonTriggeringExamples: [
            "if condition {\n",
            "if (a, b) == (0, 1) {\n",
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
            "switch foo {\n",
        ],
        triggeringExamples: [
            "if (condition) {\n",
            "if(condition) {\n",
            "for (item in collection) {\n",
            "for (var index = 0; index < 42; index++) {\n",
            "for(item in collection) {\n",
            "for(var index = 0; index < 42; index++) {\n",
            "guard (condition) else {\n",
            "while (condition) {\n",
            "while(condition) {\n",
            "} while (condition) {\n",
            "} while(condition) {\n",
            "do { ; } while(condition) {\n",
            "do { ; } while (condition) {\n",
            "switch (foo) {\n",
        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        let statements = ["if", "for", "guard", "switch", "while"]
        return statements.flatMap { statementKind -> [StyleViolation] in
            let pattern = statementKind == "guard"
                ? "\(statementKind)\\s*\\([^,]*\\)\\s*else\\s*\\{"
                : "\(statementKind)\\s*\\([^,]*\\)\\s*\\{"
            return file.matchPattern(pattern).flatMap { match, syntaxKinds in
                if syntaxKinds.first != .Keyword {
                    return nil
                }
                return StyleViolation(ruleDescription: self.dynamicType.description,
                    location: Location(file: file, offset: match.location),
                    reason: "\(statementKind) statements shouldn't wrap their conditionals in " +
                    "parentheses.")
                }
        }
    }
}
