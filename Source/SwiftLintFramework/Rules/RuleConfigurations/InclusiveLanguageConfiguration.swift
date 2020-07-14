private enum ConfigurationKey: String {
    case severity
    case allow
    case deny
}

public struct InclusiveLanguageConfiguration: RuleConfiguration, Equatable {
    public var severityConfiguration = SeverityConfiguration(.warning)
    public var denyList: Set<String>

    public var consoleDescription: String {
        severityConfiguration.consoleDescription
            + ", deny: \(denyList.sorted())"
    }

    public var severity: ViolationSeverity {
        severityConfiguration.severity
    }

    private let defaultDenyList: Set<String> = [
        "whitelist",
        "blacklist",
        "master",
        "slave"
    ]

    public init() {
        self.denyList = defaultDenyList
    }

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let severityString = configuration[ConfigurationKey.severity.rawValue] {
            try severityConfiguration.apply(configuration: severityString)
        }

        let configAllowList = lowercasedList(for: .allow, from: configuration)
        let configDenyList = lowercasedList(for: .deny, from: configuration)
        self.denyList = defaultDenyList.union(configDenyList).subtracting(configAllowList)
    }

    private func lowercasedList(for key: ConfigurationKey, from config: [String: Any]) -> [String] {
        let list = config[key.rawValue] as? [String] ?? []
        return list.map { $0.lowercased() }
    }
}
