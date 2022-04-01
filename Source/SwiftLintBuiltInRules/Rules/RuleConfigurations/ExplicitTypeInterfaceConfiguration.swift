struct ExplicitTypeInterfaceConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = ExplicitTypeInterfaceRule

    enum VariableKind: String, CaseIterable {
        case instance
        case local
        case `static`
        case `class`

        static let all = Set(allCases)
    }

    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)

    private(set) var allowedKinds = VariableKind.all

    private(set) var allowRedundancy = false

    var parameterDescription: RuleConfigurationDescription {
        let excludedKinds = VariableKind.all.subtracting(allowedKinds).map(\.rawValue).sorted()
        severityConfiguration
        "excluded" => .list(excludedKinds.map { .symbol($0) })
        "allow_redundancy" => .flag(allowRedundancy)
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }
        for (key, value) in configuration {
            switch (key, value) {
            case ("severity", let severityString as String):
                try severityConfiguration.apply(configuration: severityString)
            case ("excluded", let excludedStrings as [String]):
                allowedKinds.subtract(excludedStrings.compactMap(VariableKind.init(rawValue:)))
            case ("allow_redundancy", let allowRedundancy as Bool):
                self.allowRedundancy = allowRedundancy
            default:
                throw Issue.unknownConfiguration(ruleID: Parent.identifier)
            }
        }
    }
}
