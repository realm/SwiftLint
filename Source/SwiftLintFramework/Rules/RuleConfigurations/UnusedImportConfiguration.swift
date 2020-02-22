/// The configuration payload mapping an imported module to a set of modules that are allowed to be
/// transitively imported.
public struct TransitiveModuleConfiguration: Equatable {
    /// The module imported in a source file.
    public let importedModule: String
    /// The set of modules that can be transitively imported by `importedModule`.
    public let transitivelyImportedModules: [String]

    init(configuration: Any) throws {
        guard let configurationDict = configuration as? [String: Any],
            Set(configurationDict.keys) == ["module", "allowed_transitive_imports"],
            let importedModule = configurationDict["module"] as? String,
            let transitivelyImportedModules = configurationDict["allowed_transitive_imports"] as? [String]
        else {
            throw ConfigurationError.unknownConfiguration
        }
        self.importedModule = importedModule
        self.transitivelyImportedModules = transitivelyImportedModules
    }
}

public struct UnusedImportConfiguration: RuleConfiguration, Equatable {
    public var consoleDescription: String {
        return [
            "severity: \(severity.consoleDescription)",
            "require_explicit_imports: \(requireExplicitImports)",
            "allowed_transitive_imports: \(allowedTransitiveImports)"
        ].joined(separator: ", ")
    }

    public private(set) var severity: SeverityConfiguration
    public private(set) var requireExplicitImports: Bool
    public private(set) var allowedTransitiveImports: [TransitiveModuleConfiguration]

    public init(severity: ViolationSeverity, requireExplicitImports: Bool,
                allowedTransitiveImports: [TransitiveModuleConfiguration]) {
        self.severity = SeverityConfiguration(severity)
        self.requireExplicitImports = requireExplicitImports
        self.allowedTransitiveImports = allowedTransitiveImports
    }

    public mutating func apply(configuration: Any) throws {
        guard let configurationDict = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let severityConfiguration = configurationDict["severity"] {
            try severity.apply(configuration: severityConfiguration)
        }
        if let requireExplicitImports = configurationDict["require_explicit_imports"] as? Bool {
            self.requireExplicitImports = requireExplicitImports
        }
        if let allowedTransitiveImports = configurationDict["allowed_transitive_imports"] as? [Any] {
            self.allowedTransitiveImports = try allowedTransitiveImports.map(TransitiveModuleConfiguration.init)
        }
    }
}
