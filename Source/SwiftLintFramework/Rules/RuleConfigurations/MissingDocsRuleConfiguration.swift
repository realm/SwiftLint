public struct MissingDocsRuleConfiguration: RuleConfiguration, Equatable {
    private(set) var parameters = [RuleParameter<AccessControlLevel>]()
    private(set) var mindIncompleteDocs: Bool = true

    private static let incompleteDocsKey: String = "mind_incomplete_docs"

    public var consoleDescription: String {
        var items = parameters.group { $0.severity }.sorted { $0.key.rawValue < $1.key.rawValue }.map {
            "\($0.rawValue): \($1.map { $0.value.description }.sorted(by: <).joined(separator: ", "))"
        }
        items.append("\(MissingDocsRuleConfiguration.incompleteDocsKey): \(mindIncompleteDocs)")
        return items.joined(separator: ", ")
    }

    public mutating func apply(configuration: Any) throws {
        guard var dict = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let mindIncompleteDocs = dict[MissingDocsRuleConfiguration.incompleteDocsKey] as? Bool {
            self.mindIncompleteDocs = mindIncompleteDocs
            dict.removeValue(forKey: MissingDocsRuleConfiguration.incompleteDocsKey)
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
