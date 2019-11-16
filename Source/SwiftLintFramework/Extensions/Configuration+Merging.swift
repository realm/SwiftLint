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
            fileGraph: nil, // The merge result doesn't have a file "background" anymore
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
        let parentRootPath = rootDirectory?.bridge().pathComponents ?? []
        var childRootPath = childConfiguration.rootDirectory?.bridge().pathComponents ?? []

        // Safeguard against the case that should'nt happen
        guard childRootPath.starts(with: parentRootPath) else {
            return (included: childConfiguration.includedPaths, excluded: childConfiguration.excludedPaths)
        }

        // Express child paths relative to parent root directory
        childRootPath.removeFirst(parentRootPath.count)
        let prefix = childRootPath.joined(separator: "/")
        let childConfigIncluded = childConfiguration.includedPaths.map { "\(prefix)/\($0)" }
        let childConfigExcluded = childConfiguration.excludedPaths.map { "\(prefix)/\($0)" }

        // Prefer child configuration over parent configuration
        return (
            included: includedPaths.filter { !childConfigExcluded.contains($0) } + childConfigIncluded,
            excluded: excludedPaths.filter { !childConfigIncluded.contains($0) } + childConfigExcluded
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
        return (file.path?.bridge().deletingLastPathComponent).map(configuration(forDirectory:)) ?? self
    }

    private func configuration(forDirectory directory: String) -> Configuration {
        // Allow nested configuration processing even if config wasn't created via files (-> rootDir present)
        let rootDirectory = self.rootDirectory ?? FileManager.default.currentDirectoryPath.bridge().standardizingPath

        let directoryNSString = directory.bridge()
        let fullDirectory = directoryNSString.absolutePathRepresentation()
        let configurationSearchPath = directoryNSString.appendingPathComponent(Configuration.fileName)
        let cacheIdentifier = "nestedPath" + rootDirectory + configurationSearchPath

        if Configuration.getIsNestedConfigurationSelf(forIdentifier: cacheIdentifier) == true {
            return self
        } else if let cached = Configuration.getCached(forIdentifier: cacheIdentifier) {
            return cached
        } else {
            var config: Configuration

            if directory == rootDirectory {
                // Use self if at level self
                config = self
            } else if
                FileManager.default.fileExists(atPath: configurationSearchPath),
                fileGraph?.includesFile(atPath: configurationSearchPath) != true
            {
                // Use self merged with the nested config that was found
                // iff that nested config has not already been used to build the main config

                // Ignore parent_config / child_config specifications of nested configs
                config = merged(
                    with: Configuration(
                        configurationFiles: [configurationSearchPath],
                        rootPath: fullDirectory,
                        optional: false,
                        quiet: true,
                        ignoreParentAndChildConfigs: true
                    )
                )
                config.fileGraph = fileGraph

                // Cache merged result to circumvent heavy merge recomputations
                config.setCached(forIdentifier: cacheIdentifier)
            } else if directory != "/" {
                // If we are not at the root path, continue down the tree
                config = configuration(forDirectory: directoryNSString.deletingLastPathComponent)
            } else {
                // Fallback to self
                config = self
            }

            if config == self {
                // Cache that for this path, the config equals self
                Configuration.setIsNestedConfigurationSelf(forIdentifier: cacheIdentifier, value: true)
            }

            return config
        }
    }
}
