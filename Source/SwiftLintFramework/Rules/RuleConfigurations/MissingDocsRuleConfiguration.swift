public struct MissingDocsRuleConfiguration: RuleConfiguration, Equatable {
    private(set) var parameters = [RuleParameter<AccessControlLevel>]()

    public var consoleDescription: String {
        return parameters.group { $0.severity }.sorted { $0.key.rawValue < $1.key.rawValue }.map {
            "\($0.rawValue): \($1.map { $0.value.description }.sorted(by: <).joined(separator: ", "))"
        }.joined(separator: ", ")
    }

    public mutating func apply(configuration: Any) throws {
        guard let dict = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }
        let parameters = try dict.flatMap { (key: String, value: Any) -> [RuleParameter<AccessControlLevel>] in
            guard let severity = ViolationSeverity(rawValue: key) else {
                throw ConfigurationError.unknownConfiguration
            }
            if let array = [String].array(of: value) {
                return try array.map {
                    guard let acl = AccessControlLevel(description: $0) else {
                        throw ConfigurationError.unknownConfiguration
                    }
                    return RuleParameter<AccessControlLevel>(severity: severity, value: acl)
                }
            } else if let string = value as? String, let acl = AccessControlLevel(description: string) {
                return [RuleParameter<AccessControlLevel>(severity: severity, value: acl)]
            }
            throw ConfigurationError.unknownConfiguration
        }
        guard parameters.count == parameters.map({ $0.value }).unique.count else {
            throw ConfigurationError.unknownConfiguration
        }
        self.parameters = parameters
    }
}
