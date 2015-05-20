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

func describeExample(example: RuleExample) -> StructuredText {
    return .Joined([
        .Header(level: 1, text: example.ruleName),
        .Paragraph(example.ruleDescription),
        .Header(level: 2, text: "Correct examples"),
        .List(items: example.correctExamples.map { .Paragraph($0) }),
        .Header(level: 2, text: "Failing examples"),
        .List(items: example.failingExamples.map { .Paragraph($0) })
    ])
}



struct ExplainCommand: CommandType {
    let verb = "explain"
    let function = "Display the list of rules and examples"
    
    func run(mode: CommandMode) -> Result<(), CommandantError<()>> {
        switch mode {
        case let .Arguments:
            for example: RuleExample in Linter.explainableRules {
                println(describeExample(example).ansi)
                                
            }
            
        default:
            break
        }
        return success()
    }

}