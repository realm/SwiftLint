import SwiftLintFramework

public extension RuleDescription {
    func with(nonTriggeringExamples: [Example],
              triggeringExamples: [Example]) -> RuleDescription {
        return RuleDescription(identifier: identifier,
                               name: name,
                               description: description,
                               kind: kind,
                               nonTriggeringExamples: nonTriggeringExamples,
                               triggeringExamples: triggeringExamples,
                               corrections: corrections,
                               deprecatedAliases: deprecatedAliases)
    }

    func with(nonTriggeringExamples: [Example]) -> RuleDescription {
        return with(nonTriggeringExamples: nonTriggeringExamples,
                    triggeringExamples: triggeringExamples)
    }

    func with(triggeringExamples: [Example]) -> RuleDescription {
        return with(nonTriggeringExamples: nonTriggeringExamples,
                    triggeringExamples: triggeringExamples)
    }

    func with(corrections: [Example: Example]) -> RuleDescription {
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
