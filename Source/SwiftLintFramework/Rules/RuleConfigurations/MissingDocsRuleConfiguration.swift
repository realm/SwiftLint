struct MissingDocsRuleConfiguration: RuleConfiguration, Equatable {
    private(set) var parameters = [
        RuleParameter<AccessControlLevel>(severity: .warning, value: .open),
        RuleParameter<AccessControlLevel>(severity: .warning, value: .public)
    ]
    private(set) var excludesExtensions = true
    private(set) var excludesInheritedTypes = true
    private(set) var excludesTrivialInit = false

    var consoleDescription: String {
        let parametersDescription = parameters.group { $0.severity }.sorted { $0.key.rawValue < $1.key.rawValue }.map {
            "\($0.rawValue): \($1.map { $0.value.description }.sorted(by: <).joined(separator: ", "))"
        }.joined(separator: ", ")

        if parametersDescription.isEmpty {
            return [
                "excludes_extensions: \(excludesExtensions)",
                "excludes_inherited_types: \(excludesInheritedTypes)",
                "excludes_trivial_init: \(excludesTrivialInit)"
            ]
            .joined(separator: ", ")
        } else {
            return [
                parametersDescription,
                "excludes_extensions: \(excludesExtensions)",
                "excludes_inherited_types: \(excludesInheritedTypes)",
                "excludes_trivial_init: \(excludesTrivialInit)"
            ]
            .joined(separator: ", ")
        }
    }

    mutating func apply(configuration: Any) throws {
        guard let dict = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let shouldExcludeExtensions = dict["excludes_extensions"] as? Bool {
            excludesExtensions = shouldExcludeExtensions
        }

        if let shouldExcludeInheritedTypes = dict["excludes_inherited_types"] as? Bool {
            excludesInheritedTypes = shouldExcludeInheritedTypes
        }

        if let excludesTrivialInit = dict["excludes_trivial_init"] as? Bool {
            self.excludesTrivialInit = excludesTrivialInit
        }

        if let parameters = try parameters(from: dict) {
            self.parameters = parameters
        }
    }

    private func parameters(from dict: [String: Any]) throws -> [RuleParameter<AccessControlLevel>]? {
        var parameters: [RuleParameter<AccessControlLevel>] = []

        for (key, value) in dict {
            guard let severity = ViolationSeverity(rawValue: key) else {
                continue
            }

            if let array = [String].array(of: value) {
                let rules: [RuleParameter<AccessControlLevel>] = try array
                    .map { val -> RuleParameter<AccessControlLevel> in
                        guard let acl = AccessControlLevel(description: val) else {
                            throw ConfigurationError.unknownConfiguration
                        }
                        return RuleParameter<AccessControlLevel>(severity: severity, value: acl)
                    }

                parameters.append(contentsOf: rules)
            } else if let string = value as? String, let acl = AccessControlLevel(description: string) {
                let rule = RuleParameter<AccessControlLevel>(severity: severity, value: acl)

                parameters.append(rule)
            }
        }

        guard parameters.count == parameters.map({ $0.value }).unique.count else {
            throw ConfigurationError.unknownConfiguration
        }

        return parameters.isNotEmpty ? parameters : nil
    }
}
