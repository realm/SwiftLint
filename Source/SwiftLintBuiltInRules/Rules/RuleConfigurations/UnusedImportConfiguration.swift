import SwiftLintCore

/// The configuration payload mapping an imported module to a set of modules that are allowed to be
/// transitively imported.
struct TransitiveModuleConfiguration<Parent: Rule>: Equatable, AcceptableByConfigurationElement {
    /// The module imported in a source file.
    let importedModule: String
    /// The set of modules that can be transitively imported by `importedModule`.
    let transitivelyImportedModules: [String]

    init(fromAny configuration: Any, context _: String) throws {
        guard let configurationDict = configuration as? [String: Any],
            Set(configurationDict.keys) == ["module", "allowed_transitive_imports"],
            let importedModule = configurationDict["module"] as? String,
            let transitivelyImportedModules = configurationDict["allowed_transitive_imports"] as? [String]
        else {
            throw Issue.invalidConfiguration(ruleID: Parent.identifier)
        }
        self.importedModule = importedModule
        self.transitivelyImportedModules = transitivelyImportedModules
    }

    func asOption() -> OptionType {
        .nest {
            importedModule => .list(transitivelyImportedModules.map { .string($0) })
        }
    }
}

@AutoConfigParser
struct UnusedImportConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = UnusedImportRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>.warning
    @ConfigurationElement(key: "require_explicit_imports")
    private(set) var requireExplicitImports = false
    @ConfigurationElement(key: "allowed_transitive_imports")
    private(set) var allowedTransitiveImports = [TransitiveModuleConfiguration<Parent>]()
    /// A set of modules to never remove the imports of.
    @ConfigurationElement(key: "always_keep_imports")
    private(set) var alwaysKeepImports = [String]()
}
