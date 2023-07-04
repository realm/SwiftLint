import SwiftLintCore

struct MissingDocsConfiguration: RuleConfiguration, Equatable {
    typealias Parent = MissingDocsRule

    private(set) var parameters = [
        RuleParameter<AccessControlLevel>(severity: .warning, value: .open),
        RuleParameter<AccessControlLevel>(severity: .warning, value: .public)
    ]

    @ConfigurationElement(key: "excludes_extensions")
    private(set) var excludesExtensions = true
    @ConfigurationElement(key: "excludes_inherited_types")
    private(set) var excludesInheritedTypes = true
    @ConfigurationElement(key: "excludes_trivial_init")
    private(set) var excludesTrivialInit = false

    var parameterDescription: RuleConfigurationDescription? {
        let parametersDescription = parameters.group { $0.severity }
            .sorted { $0.key.rawValue < $1.key.rawValue }
        if parametersDescription.isNotEmpty {
            for (severity, values) in parametersDescription {
                severity.rawValue => .list(values.map(\.value.description).sorted().map { .symbol($0) })
            }
        }
        $excludesExtensions => .flag(excludesExtensions)
        $excludesInheritedTypes => .flag(excludesInheritedTypes)
        $excludesTrivialInit => .flag(excludesTrivialInit)
    }

    mutating func apply(configuration: Any) throws {
        guard let dict = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        if let shouldExcludeExtensions = dict[$excludesExtensions] as? Bool {
            excludesExtensions = shouldExcludeExtensions
        }

        if let shouldExcludeInheritedTypes = dict[$excludesInheritedTypes] as? Bool {
            excludesInheritedTypes = shouldExcludeInheritedTypes
        }

        if let excludesTrivialInit = dict[$excludesTrivialInit] as? Bool {
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
                            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
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
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        return parameters.isNotEmpty ? parameters : nil
    }
}
