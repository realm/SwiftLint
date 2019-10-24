import Foundation
import SourceKittenFramework

/// GENERAL NOTE ON MERGING: The child configuration is added on top of the parent configuration
/// and is preferred if in doubt!

extension Configuration {
    // MARK: - Methods: Merging
    internal func merged(with childConfiguration: Configuration) -> Configuration {
        let mergedIncludedAndExcluded = self.mergedIncludedAndExcluded(with: childConfiguration)

        return Configuration(
            rulesWrapper: rulesWrapper.merged(with: childConfiguration.rulesWrapper),
            fileGraph: nil,
            includedPaths: mergedIncludedAndExcluded.included,
            excludedPaths: mergedIncludedAndExcluded.excluded,
            indentation: childConfiguration.indentation,
            warningThreshold: mergedWarningTreshold(with: childConfiguration),
            reporter: reporter,
            cachePath: cachePath
        )
    }

    private func mergedIncludedAndExcluded(
        with childConfiguration: Configuration
    ) -> (included: [String], excluded: [String]) {
        if rootDirectory != childConfiguration.rootDirectory {
            // Configurations aren't on same level => use child configuration
            return (included: childConfiguration.includedPaths, excluded: childConfiguration.excludedPaths)
        }

        // Prefer child configuration over parent configuration
        return (
            included: includedPaths.filter { !childConfiguration.excludedPaths.contains($0) }
                + childConfiguration.includedPaths,
            excluded: excludedPaths.filter { !childConfiguration.includedPaths.contains($0) }
                + childConfiguration.excludedPaths
        )
    }

    private func mergedWarningTreshold(
        with childConfiguration: Configuration
    ) -> Int? {
        if let parentWarningTreshold = warningThreshold {
            if let childWarningTreshold = childConfiguration.warningThreshold {
                return min(childWarningTreshold, parentWarningTreshold)
            } else {
                return parentWarningTreshold
            }
        } else {
            return childConfiguration.warningThreshold
        }
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
        // Allow nested configuration processing even if config wasn't created via files (-> rootDir present)
        let rootDirectory = self.rootDirectory ?? FileManager.default.currentDirectoryPath.bridge().standardizingPath

        // Include nested configurations, but ignore their parent_config / child_config specifications!
        let pathNSString = path.bridge()
        let configurationSearchPath = pathNSString.appendingPathComponent(Configuration.fileName)
        let fullPath = pathNSString.absolutePathRepresentation()
        let cacheIdentifier = "nestedPath" + rootDirectory + configurationSearchPath

        if let cached = Configuration.getCached(forIdentifier: cacheIdentifier) {
            return cached
        } else {
            if path == rootDirectory {
                // Use self if at level self
                return self
            } else if
                FileManager.default.fileExists(atPath: configurationSearchPath)//,
                // fileGraph.includesFile(atPath: configurationSearchPath) == false TODO
            {
                // Use self merged with the nested config that was found
                // iff that nested config has not already been used to build the main config
                queuedPrintError("warning: \(configurationSearchPath) is included as nested.") // TODO: Remove
                let config = merged(
                    with: Configuration(
                        configurationFiles: [configurationSearchPath],
                        rootPath: fullPath,
                        optional: false,
                        quiet: true,
                        ignoreParentAndChildConfigs: true
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
