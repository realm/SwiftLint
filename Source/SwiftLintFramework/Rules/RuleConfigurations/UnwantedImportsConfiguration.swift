public struct UnwantedImportsConfiguration: RuleConfiguration, Equatable {
    typealias Severity = ViolationSeverity

    let errorKeyword = "error"
    var unwantedImports: [String: ViolationSeverity] = [:]

    public var consoleDescription: String {
        let imports = self.unwantedImports.sorted(by: { $0.key < $1.key }) .compactMap { module, severity in
            return "[module: \"\(module)\", severity: \(severity.rawValue)]]"
        }.joined(separator: ", ")

        let instructions = "No unwanted imports configured.  In config add 'unwanted_imports' to 'opt_in_rules' and " +
                           "config using :\n\n" +
                           "'unwanted_imports:\n" +
                           "  {Module Name}:{warning|error}\n"

        return imports.isEmpty ? instructions : imports
    }

    public mutating func apply(configuration: Any) throws {
        guard let config = configuration as? [String: String] else {
            throw ConfigurationError.unknownConfiguration
        }

        register(unwantedImports: config)
    }

    /// Parsed the unwanted imports into the unwantedImports array using the key as the module name and the value as the
    /// severity level.
    ///
    /// - Parameter unwantedImports: Dictionary with the module name as key and severity level as value.
    mutating func register(unwantedImports: [String: String]) {
        for (module, severity) in unwantedImports {
            self.unwantedImports[module] = (severity == errorKeyword) ? Severity.error: Severity.warning
        }
    }

    public static func == (lhs: UnwantedImportsConfiguration, rhs: UnwantedImportsConfiguration) -> Bool {
        return lhs.unwantedImports == rhs.unwantedImports
    }
}
