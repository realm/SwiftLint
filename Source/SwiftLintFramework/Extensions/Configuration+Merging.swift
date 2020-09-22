import Foundation
import SourceKittenFramework

extension Configuration {
    /// Returns a new configuration that applies to the specified file by merging the current configuration with any
    /// child configurations in the directory inheritance graph present until the level of the specified file.
    ///
    /// - parameter file: The file for which to obtain a configuration value.
    ///
    /// - returns: A new configuration.
    public func configuration(for file: SwiftLintFile) -> Configuration {
        if let containingDir = file.path?.bridge().deletingLastPathComponent {
            return configuration(forPath: containingDir)
        }
        return self
    }

    private func configuration(forPath path: String) -> Configuration {
        if path == rootDirectory {
            return self
        }

        let pathNSString = path.bridge()
        let configurationSearchPath = pathNSString.appendingPathComponent(Configuration.fileName)

        // If a configuration exists and it isn't us, load and merge the configurations
        if configurationSearchPath != configurationPath &&
            FileManager.default.fileExists(atPath: configurationSearchPath) {
            let fullPath = pathNSString.absolutePathRepresentation()
            let customRuleIdentifiers = (rules.first(where: { $0 is CustomRules }) as? CustomRules)?
                .configuration.customRuleConfigurations.map { $0.identifier }
            let config = Configuration.getCached(atPath: fullPath) ??
                Configuration(
                    path: configurationSearchPath,
                    rootPath: fullPath,
                    optional: false,
                    quiet: true,
                    customRulesIdentifiers: customRuleIdentifiers ?? []
                )
            return merge(with: config)
        }

        // If we are not at the root path, continue down the tree
        if path != rootPath && path != "/" {
            return configuration(forPath: pathNSString.deletingLastPathComponent)
        }

        // If nothing else, return self
        return self
    }

    private var rootDirectory: String? {
        guard let rootPath = rootPath else {
            return nil
        }

        var isDirectoryObjC: ObjCBool = false
        guard FileManager.default.fileExists(atPath: rootPath, isDirectory: &isDirectoryObjC) else {
            return nil
        }

        if isDirectoryObjC.boolValue {
            return rootPath
        } else {
            return rootPath.bridge().deletingLastPathComponent
        }
    }

    private struct HashableRule: Hashable {
        fileprivate let rule: Rule

        fileprivate static func == (lhs: HashableRule, rhs: HashableRule) -> Bool {
            // Don't use `isEqualTo` in case its internal implementation changes from
            // using the identifier to something else, which could mess up with the `Set`
            return type(of: lhs.rule).description.identifier == type(of: rhs.rule).description.identifier
        }

        fileprivate func hash(into hasher: inout Hasher) {
            hasher.combine(type(of: rule).description.identifier)
        }
    }

    private func mergeCustomRules(mergedRules: [Rule], configuration: Configuration) -> [Rule] {
        guard
            let thisCustomRules = rules.first(where: { $0 is CustomRules }) as? CustomRules,
            let otherCustomRules = configuration.rules.first(where: { $0 is CustomRules }) as? CustomRules else {
            return mergedRules
        }
        let customRulesFilter: (RegexConfiguration) -> (Bool)
        switch configuration.rulesMode {
        case .allEnabled:
            customRulesFilter = { _ in true }
        case let .whitelisted(whitelistedRules):
            customRulesFilter = { whitelistedRules.contains($0.identifier) }
        case let .default(disabledRules, _):
            customRulesFilter = { !disabledRules.contains($0.identifier) }
        }
        var customRules = CustomRules()
        var configuration = CustomRulesConfiguration()
        configuration.customRuleConfigurations = Set(
            thisCustomRules.configuration.customRuleConfigurations
        ).union(
            Set(otherCustomRules.configuration.customRuleConfigurations)
        ).filter(customRulesFilter)
        customRules.configuration = configuration
        return mergedRules.filter { !($0 is CustomRules) } + [customRules]
    }

    private func mergingRules(with configuration: Configuration) -> [Rule] {
        let regularMergedRules: [Rule]
        switch configuration.rulesMode {
        case .allEnabled:
            // Technically not possible yet as it's not configurable in a .swiftlint.yml file,
            // but implemented for completeness
            regularMergedRules = configuration.rules
        case .whitelisted(let whitelistedRules):
            // Use an intermediate set to filter out duplicate rules when merging configurations
            // (always use the nested rule first if it exists)
            regularMergedRules = Set(configuration.rules.map(HashableRule.init))
                .union(rules.map(HashableRule.init))
                .map { $0.rule }
                .filter { rule in
                    return whitelistedRules.contains(type(of: rule).description.identifier)
                }
        case let .default(disabled, optIn):
            // Same here
            regularMergedRules = Set(
                configuration.rules
                    // Enable rules that are opt-in by the nested configuration
                    .filter { rule in
                        return optIn.contains(type(of: rule).description.identifier)
                    }
                    .map(HashableRule.init)
                )
                // And disable rules that are disabled by the nested configuration
                .union(
                    rules.filter { rule in
                        return !disabled.contains(type(of: rule).description.identifier)
                    }.map(HashableRule.init)
                )
                .map { $0.rule }
        }
        return mergeCustomRules(mergedRules: regularMergedRules, configuration: configuration)
    }

    internal func merge(with configuration: Configuration) -> Configuration {
        return Configuration(
            rulesMode: configuration.rulesMode, // Use the rulesMode used to build the merged configuration
            included: configuration.included, // Always use the nested included directories
            excluded: configuration.excluded, // Always use the nested excluded directories
            // The minimum warning threshold if both exist, otherwise the nested,
            // and if it doesn't exist try to use the parent one
            warningThreshold: warningThreshold.map { warningThreshold in
                return min(configuration.warningThreshold ?? .max, warningThreshold)
            } ?? configuration.warningThreshold,
            reporter: reporter, // Always use the parent reporter
            rules: mergingRules(with: configuration),
            cachePath: cachePath, // Always use the parent cache path
            rootPath: configuration.rootPath,
            indentation: configuration.indentation,
            allowZeroLintableFiles: configuration.allowZeroLintableFiles
        )
    }
}
