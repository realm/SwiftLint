internal struct HashableConfigurationRuleWrapperWrapper: Hashable {
    let configurationRuleWrapper: ConfigurationRuleWrapper

    static func == (
        lhs: HashableConfigurationRuleWrapperWrapper, rhs: HashableConfigurationRuleWrapperWrapper
    ) -> Bool {
        // Only use identifier for equality check (not taking config into account)
        return type(of: lhs.configurationRuleWrapper.rule).description.identifier
            == type(of: rhs.configurationRuleWrapper.rule).description.identifier
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(type(of: configurationRuleWrapper.rule).description.identifier)
    }
}
