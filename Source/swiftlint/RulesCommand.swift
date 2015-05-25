//
//  ExplainCommand.swift
//  SwiftLint
//
//  Created by Chris Eidhof on 20/05/15.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Foundation
import Commandant
import LlamaKit
import SwiftLintFramework
import SourceKittenFramework

func describeExample(example: RuleExample) -> StructuredText {
    var description: [StructuredText] = [
        .Header(level: 1, text: example.ruleName),
        .Paragraph(example.ruleDescription)
    ]
    if example.showExamples {
        description += [
            .Header(level: 2, text: "Correct examples"),
            .List(items: example.correctExamples.map { .Paragraph($0.chomped) }),
            .Header(level: 2, text: "Failing examples"),
            .List(items: example.failingExamples.map { .Paragraph($0.chomped) })
        ]
    }
    return .Joined(description)
}



struct RulesCommand: CommandType {
    let verb = "rules"
    let function = "Display the list of rules and examples"
    
    func run(mode: CommandMode) -> Result<(), CommandantError<()>> {
        switch mode {
        case let .Arguments:
            let ruleExamples = Linter(file: File(contents: "")).explainableRules
            let text = StructuredText.Joined(ruleExamples.map(describeExample))
            println(text.ansi)
            
        default:
            break
        }
        return success()
    }

}