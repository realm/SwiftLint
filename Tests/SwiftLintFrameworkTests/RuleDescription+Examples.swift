//
//  RuleDescription+Examples.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 02/07/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import SwiftLintFramework

extension RuleDescription {
    func with(nonTriggeringExamples: [String]) -> RuleDescription {
        return RuleDescription(identifier: identifier,
                               name: name,
                               description: description,
                               kind: kind,
                               nonTriggeringExamples: nonTriggeringExamples,
                               triggeringExamples: triggeringExamples,
                               corrections: corrections,
                               deprecatedAliases: deprecatedAliases)
    }

    func with(triggeringExamples: [String]) -> RuleDescription {
        return RuleDescription(identifier: identifier,
                               name: name,
                               description: description,
                               kind: kind,
                               nonTriggeringExamples: nonTriggeringExamples,
                               triggeringExamples: triggeringExamples,
                               corrections: corrections,
                               deprecatedAliases: deprecatedAliases)
    }

    func with(corrections: [String: String]) -> RuleDescription {
        return RuleDescription(identifier: identifier,
                               name: name,
                               description: description,
                               kind: kind,
                               nonTriggeringExamples: nonTriggeringExamples,
                               triggeringExamples: triggeringExamples,
                               corrections: corrections,
                               deprecatedAliases: deprecatedAliases)
    }
}
