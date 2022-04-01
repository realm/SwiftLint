struct ImplicitReturnConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = ImplicitReturnRule

    enum ReturnKind: String, CaseIterable {
        case closure
        case function
        case getter
    }

    static let defaultIncludedKinds = Set(ReturnKind.allCases)

    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)

    private(set) var includedKinds = Self.defaultIncludedKinds

    var parameterDescription: RuleConfigurationDescription {
        let includedKinds = self.includedKinds.map { $0.rawValue }
        severityConfiguration
        "included" => .list(includedKinds.sorted().map { .symbol($0) })
    }

    init(includedKinds: Set<ReturnKind> = Self.defaultIncludedKinds) {
        self.includedKinds = includedKinds
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        if let includedKinds = configuration["included"] as? [String] {
            self.includedKinds = try Set(includedKinds.map {
                guard let kind = ReturnKind(rawValue: $0) else {
                    throw Issue.unknownConfiguration(ruleID: Parent.identifier)
                }

                return kind
            })
        }

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }

    func isKindIncluded(_ kind: ReturnKind) -> Bool {
        return self.includedKinds.contains(kind)
    }
}
