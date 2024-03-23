struct RequiredEnumCaseConfiguration: RuleConfiguration {
    typealias Parent = RequiredEnumCaseRule

    struct RequiredCase: Hashable {
        var name: String
        var severity: ViolationSeverity

        init(name: String, severity: ViolationSeverity = .warning) {
            self.name = name
            self.severity = severity
        }
    }

    var protocols: [String: Set<RequiredCase>] = [:]

    var parameterDescription: RuleConfigurationDescription? {
        if protocols.isEmpty {
            "{Protocol Name}" => .nest {
                "{Case Name 1}" => .symbol("{warning|error}")
                "{Case Name 2}" => .symbol("{warning|error}")
            }
        } else {
            for (protocolName, requiredCases) in protocols.sorted(by: { $0.key < $1.key }) {
                protocolName => .nest {
                    for requiredCase in requiredCases.sorted(by: { $0.name < $1.name }) {
                        requiredCase.name => .symbol(requiredCase.severity.rawValue)
                    }
                }
            }
        }
    }

    mutating func apply(configuration: Any) throws {
        guard let config = configuration as? [String: [String: String]] else {
            throw Issue.invalidConfiguration(ruleID: Parent.identifier)
        }

        register(protocols: config)
    }

    mutating func register(protocols: [String: [String: String]]) {
        for (name, cases) in protocols {
            register(protocol: name, cases: cases)
        }
    }

    mutating func register(protocol name: String, cases: [String: String]) {
        var requiredCases: Set<RequiredCase> = []

        for (caseName, severity) in cases {
            let parsedSeverity: ViolationSeverity = (severity == "error") ? .error : .warning
            requiredCases.insert(RequiredCase(name: caseName, severity: parsedSeverity))
        }

        protocols[name] = requiredCases
    }
}
