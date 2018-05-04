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
