/// The configuration payload mapping an imported module to a set of modules that are allowed to be
/// transitively imported.
struct TransitiveModuleConfiguration<Parent: Rule>: Equatable {
    /// The module imported in a source file.
    let importedModule: String
    /// The set of modules that can be transitively imported by `importedModule`.
    let transitivelyImportedModules: [String]

    init(configuration: Any) throws {
        guard let configurationDict = configuration as? [String: Any],
            Set(configurationDict.keys) == ["module", "allowed_transitive_imports"],
            let importedModule = configurationDict["module"] as? String,
            let transitivelyImportedModules = configurationDict["allowed_transitive_imports"] as? [String]
        else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }
        self.importedModule = importedModule
        self.transitivelyImportedModules = transitivelyImportedModules
    }
}

struct UnusedImportConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = UnusedImportRule

    private(set) var severityConfiguration = SeverityConfiguration<Parent>.warning
    private(set) var requireExplicitImports = false
    private(set) var allowedTransitiveImports = [TransitiveModuleConfiguration<Parent>]()
    /// A set of modules to never remove the imports of.
    private(set) var alwaysKeepImports = [String]()

    var parameterDescription: RuleConfigurationDescription {
        severityConfiguration
        "require_explicit_imports" => .flag(requireExplicitImports)
        "allowed_transitive_imports" => .nest {
            for module in allowedTransitiveImports {
                module.importedModule => .list(module.transitivelyImportedModules.map { .string($0) })
            }
        }
        "always_keep_imports" => .list(alwaysKeepImports.map { .string($0) })
    }

    mutating func apply(configuration: Any) throws {
        guard let configurationDict = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        if let severity = configurationDict["severity"] {
            try severityConfiguration.apply(configuration: severity)
        }
        if let requireExplicitImports = configurationDict["require_explicit_imports"] as? Bool {
            self.requireExplicitImports = requireExplicitImports
        }
        if let allowedTransitiveImports = configurationDict["allowed_transitive_imports"] as? [Any] {
            self.allowedTransitiveImports = try allowedTransitiveImports.map(TransitiveModuleConfiguration.init)
        }
        if let alwaysKeepImports = configurationDict["always_keep_imports"] as? [String] {
            self.alwaysKeepImports = alwaysKeepImports
        }
    }
}
