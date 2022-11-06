struct RequiredEnumCaseRuleConfiguration: RuleConfiguration, Equatable {
    struct RequiredCase: Hashable {
        var name: String
        var severity: ViolationSeverity

        init(name: String, severity: ViolationSeverity = .warning) {
            self.name = name
            self.severity = severity
        }
    }

    var protocols: [String: Set<RequiredCase>] = [:]

    var consoleDescription: String {
        let protocols = self.protocols.sorted(by: { $0.key < $1.key }) .compactMap { name, required in
            let caseNames: [String] = required.sorted(by: { $0.name < $1.name }).map {
                "[name: \"\($0.name)\", severity: \"\($0.severity.rawValue)\"]"
            }

            return "[protocol: \"\(name)\", cases: [\(caseNames.joined(separator: ", "))]]"
        }.joined(separator: ", ")

        let instructions = "No protocols configured.  In config add 'required_enum_case' to 'opt_in_rules' and " +
            "config using :\n\n" +
            "'required_enum_case:\n" +
            "  {Protocol Name}:\n" +
            "    {Case Name}:{warning|error}\n" +
            "    {Case Name}:{warning|error}\n"

        return protocols.isEmpty ? instructions : protocols
    }

    mutating func apply(configuration: Any) throws {
        guard let config = configuration as? [String: [String: String]] else {
            throw ConfigurationError.unknownConfiguration
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
