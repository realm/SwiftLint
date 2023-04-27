struct ExplicitTypeInterfaceConfiguration: SeverityBasedRuleConfiguration, Equatable {
    enum VariableKind: String, CaseIterable {
        case instance
        case local
        case `static`
        case `class`

        static let all = Set(allCases)
    }

    private(set) var severityConfiguration = SeverityConfiguration(.warning)

    private(set) var allowedKinds = VariableKind.all

    private(set) var allowRedundancy = false

    var consoleDescription: String {
        let excludedKinds = VariableKind.all.subtracting(allowedKinds).map(\.rawValue).sorted()
        return "severity: \(severityConfiguration.consoleDescription)" +
            ", excluded: \(excludedKinds)" +
            ", allow_redundancy: \(allowRedundancy)"
    }

    init() {}

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
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
                throw ConfigurationError.unknownConfiguration
            }
        }
    }
}
