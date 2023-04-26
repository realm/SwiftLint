/// The rule list containing all available rules built into SwiftLintCore.
public let coreRules: [Rule.Type] = [
    CustomRules.self,
    SuperfluousDisableCommandRule.self
]
