import Foundation
import SourceKittenFramework

extension Configuration {
    // MARK: - Properties
    private var rootDirectory: String? {
        guard let rootPath = graph.rootPath else { return nil }

        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: rootPath, isDirectory: &isDirectory) else { return nil }
        return isDirectory.boolValue ? rootPath : rootPath.bridge().deletingLastPathComponent
    }

    // MARK: - Methods: Merging
    internal func merged(with configuration: Configuration) -> Configuration {
        let includedAndExcluded = mergedIncludedAndExcluded(with: configuration)

        return Configuration(
            rulesStorage: rulesStorage.merged(with: configuration.rulesStorage),
            included: includedAndExcluded.included,
            excluded: includedAndExcluded.excluded,
            // The minimum warning threshold if both exist, otherwise the nested,
            // and if it doesn't exist try to use the parent one
            warningThreshold: warningThreshold.map { warningThreshold in
                return min(configuration.warningThreshold ?? .max, warningThreshold)
            } ?? configuration.warningThreshold,
            reporter: reporter, // Always use the parent reporter
            cachePath: cachePath, // Always use the parent cache path
            graph: configuration.graph,
            indentation: configuration.indentation
        )
    }

    private func mergedIncludedAndExcluded(
        with configuration: Configuration
    ) -> (included: [String], excluded: [String]) {
        if rootDirectory != configuration.rootDirectory {
            // Configurations aren't on same level => use child configuration
            return (included: configuration.included, excluded: configuration.excluded)
        }

        // Prefer child configuration over parent configuration
        return (
            included: included.filter { !configuration.excluded.contains($0) } + configuration.included,
            excluded: excluded.filter { !configuration.included.contains($0) } + configuration.excluded
        )
    }

    // MARK: Accessing File Configurations
    /// Returns the configuration for the given file, based on self but respecting nested configurations
    public func configuration(for file: SwiftLintFile) -> Configuration {
        if let containingDir = file.path?.bridge().deletingLastPathComponent {
            return configuration(forPath: containingDir)
        }

        return self
    }

    private func configuration(forPath path: String) -> Configuration {
        let pathNSString = path.bridge()
        let configurationSearchPath = pathNSString.appendingPathComponent(Configuration.fileName)
        let fullPath = pathNSString.absolutePathRepresentation()
        let cacheIdentifier = "nestedPath" + (graph.rootPath ?? "") + configurationSearchPath

        if let cached = Configuration.getCached(forIdentifier: cacheIdentifier) {
            return cached
        } else {
            if path == rootDirectory || configurationSearchPath == configurationPath {
                // Use self if at level self
                return self
            } else if FileManager.default.fileExists(atPath: configurationSearchPath) {
                // Use self merged with the config that was found
                let config = merged(
                    with: Configuration(
                        childConfigQueue: [configurationSearchPath],
                        rootPath: fullPath,
                        optional: false,
                        quiet: true
                    )
                )

                // Cache merged result to circumvent heavy merge recomputations
                config.setCached(forIdentifier: cacheIdentifier)
                return config
            } else if path != "/" {
                // If we are not at the root path, continue down the tree
                return configuration(forPath: pathNSString.deletingLastPathComponent)
            } else {
                // Fallback to self
                return self
            }
        }
    }
}
