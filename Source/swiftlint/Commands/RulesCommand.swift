//
//  ExplainCommand.swift
//  SwiftLint
//
//  Created by Chris Eidhof on 20/05/15.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Commandant
import Result
import SwiftLintFramework

struct RulesCommand: CommandType {
    let verb = "rules"
    let function = "Display the list of rules and their identifiers"

    func run(mode: CommandMode) -> Result<(), CommandantError<()>> {
        let ruleDescriptions = Configuration.rulesFromYAML().map {
            $0.dynamicType.description.consoleDescription
        }.joinWithSeparator("\n")
        print(ruleDescriptions)
        return .Success()
    }
}
