import SwiftLintFramework

public extension RuleDescription {
    func with(nonTriggeringExamples: [Example]? = nil,
              triggeringExamples: [Example]? = nil,
              corrections: [Example: Example]? = nil) -> RuleDescription {
        RuleDescription(identifier: identifier,
                        name: name,
                        description: description,
                        kind: kind,
                        nonTriggeringExamples: nonTriggeringExamples ?? self.nonTriggeringExamples,
                        triggeringExamples: triggeringExamples ?? self.triggeringExamples,
                        corrections: corrections ?? self.corrections,
                        deprecatedAliases: deprecatedAliases)
    }
}
