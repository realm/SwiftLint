public struct ImplicitReturnConfiguration: RuleConfiguration, Equatable {
    public enum ReturnKind: String, CaseIterable {
        case closure
        case function
        case getter
    }

    public static let defaultIncludedKinds = Set(ReturnKind.allCases)

    private(set) var severityConfiguration = SeverityConfiguration(.warning)

    private(set) var includedKinds = ImplicitReturnConfiguration.defaultIncludedKinds

    public var consoleDescription: String {
        let includedKinds = self.includedKinds.map { $0.rawValue }
        return severityConfiguration.consoleDescription +
            ", included: [\(includedKinds.joined(separator: ", "))]"
    }

    public init(includedKinds: Set<ReturnKind> = ImplicitReturnConfiguration.defaultIncludedKinds) {
        self.includedKinds = includedKinds
    }

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let includedKinds = configuration["included"] as? [String] {
            self.includedKinds = try Set(includedKinds.map {
                guard let kind = ReturnKind(rawValue: $0) else {
                    throw ConfigurationError.unknownConfiguration
                }

                return kind
            })
        }

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }

    public func isKindIncluded(_ kind: ReturnKind) -> Bool {
        return self.includedKinds.contains(kind)
    }
}
