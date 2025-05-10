internal struct HashableConfigurationRuleWrapperWrapper: Hashable {
    let configurationRuleWrapper: ConfigurationRuleWrapper

    static func == (
        lhs: Self, rhs: Self
    ) -> Bool {
        // Only use identifier for equality check (not taking config into account)
        type(of: lhs.configurationRuleWrapper.rule).identifier
            == type(of: rhs.configurationRuleWrapper.rule).identifier
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(type(of: configurationRuleWrapper.rule).identifier)
    }
}
