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

    public let identifier = "control_statement"

    public func validateFile(file: File) -> [StyleViolation] {
        let statement = file.matchPattern("\\s{0,}(if|for|while)\\s{0,}\\(",
            withSyntaxKinds: [.Keyword])
        return statement.map { range in
            return StyleViolation(type: .ControlStatement,
                location: Location(file: file, offset: range.location),
                severity: .Low,
                reason: "if,for,while,do statements shouldn't wrap their conditionals in parentheses.")
        }
    }

    public let example = RuleExample(
        ruleName: "Control Statement",
        ruleDescription: "if,for,while,do statements shouldn't wrap their conditionals in parentheses.",
        nonTriggeringExamples: [
            "if condition {\n",
            "renderGif(data)\n",
            "// if (hasBetterSyntax) {\n",
            "// for (item in collection) {\n",
            "// for (var index = 0; index < 42; index++) {\n",
            "// for(item in collection) {\n",
            "// for(var index = 0; index < 42; index++) {\n",
            "for item in collection {\n",
            "for var index = 0; index < 42; index++ {\n",
            "// while (condition) {\n",
            "while condition {\n",
            "} while condition {\n",
            "// } while (condition {\n",
            "do { ; } while condition {\n"
        ],
        triggeringExamples: [
            "if (condition) {\n",
            "if(condition) {\n",
            "for (item in collection) {\n",
            "for (var index = 0; index < 42; index++) {\n",
            "for(item in collection) {\n",
            "for(var index = 0; index < 42; index++) {\n",
            "while (condition) {\n",
            "while(condition) {\n",
            "} while (condition) {\n",
            "} while(condition) {\n",
            "do { ; } while(condition) {\n",
            "do { ; } while (condition) {\n"
        ]
    )
}

