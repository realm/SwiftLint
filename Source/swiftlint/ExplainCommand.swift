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

typealias StructuredInlineText = String

extension Array {
    func dropWhile(x: Element -> Bool) -> [Element] {
        var count = 0
        while x(self[count]) { count++ }
        var copy = self
        copy.removeRange(0..<count)
        return copy
    }
}


extension String {
    var chomped: String {
        return String(reverse(self).dropWhile { $0 == "\n" }.reverse())
    }
}

enum StructuredText {
    case Header(level: Int, text: StructuredInlineText)
    case Paragraph(StructuredInlineText)
    case List(items: [StructuredText])
    case Joined([StructuredText])
    
    var markdown: String {
        switch self {
            
        case let .Header(level, t): return join("", Array(count: level, repeatedValue: "#")) + " " + t
        case .Paragraph(let t): return t.chomped
        case .List(let items): return "\n".join(items.map { "* " + $0.markdown })
        case .Joined(let items): return "\n\n".join(items.map { $0.markdown } )
        }
    }
}

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
                println(describeExample(example).markdown)
                                
            }
            
        default:
            break
        }
        return success()
    }

}