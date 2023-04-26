import Foundation
import SourceKittenFramework

/// GENERAL NOTE ON MERGING: The child configuration is added on top of the parent configuration
/// and is preferred in case of conflicts!

extension Configuration {
    // MARK: - Methods: Merging
    @_spi(TestHelper)
    public func merged(
        withChild childConfiguration: Configuration,
        rootDirectory: String
    ) -> Configuration {
        let mergedIncludedAndExcluded = self.mergedIncludedAndExcluded(
            with: childConfiguration,
            rootDirectory: rootDirectory
        )

        return Configuration(
            rulesWrapper: rulesWrapper.merged(with: childConfiguration.rulesWrapper),
            fileGraph: FileGraph(rootDirectory: rootDirectory),
            includedPaths: mergedIncludedAndExcluded.includedPaths,
            excludedPaths: mergedIncludedAndExcluded.excludedPaths,
            indentation: childConfiguration.indentation,
            warningThreshold: mergedWarningTreshold(with: childConfiguration),
            reporter: reporter,
            cachePath: cachePath,
            allowZeroLintableFiles: childConfiguration.allowZeroLintableFiles
        )
    }

    private func mergedIncludedAndExcluded(
        with childConfiguration: Configuration,
        rootDirectory: String
    ) -> (includedPaths: [String], excludedPaths: [String]) {
        // Render paths relative to their respective root paths → makes them comparable
        let childConfigIncluded = childConfiguration.includedPaths.map {
            $0.bridge().absolutePathRepresentation(rootDirectory: childConfiguration.rootDirectory)
        }

        let childConfigExcluded = childConfiguration.excludedPaths.map {
            $0.bridge().absolutePathRepresentation(rootDirectory: childConfiguration.rootDirectory)
        }

        let parentConfigIncluded = includedPaths.map {
            $0.bridge().absolutePathRepresentation(rootDirectory: self.rootDirectory)
        }

        let parentConfigExcluded = excludedPaths.map {
            $0.bridge().absolutePathRepresentation(rootDirectory: self.rootDirectory)
        }

        // Prefer child configuration over parent configuration
        let includedPaths = parentConfigIncluded.filter { !childConfigExcluded.contains($0) } + childConfigIncluded
        let excludedPaths = parentConfigExcluded.filter { !childConfigIncluded.contains($0) } + childConfigExcluded

        // Return paths relative to the provided root directory
        return (
            includedPaths: includedPaths.map { $0.path(relativeTo: rootDirectory) },
            excludedPaths: excludedPaths.map { $0.path(relativeTo: rootDirectory) }
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
    /// Returns a new configuration that applies to the specified file by merging the current configuration with any
    /// nested configurations in the directory inheritance graph present until the level of the specified file.
    ///
    /// - parameter file: The file for which to obtain a configuration value.
    ///
    /// - returns: A new configuration.
    public func configuration(for file: SwiftLintFile) -> Configuration {
        return (file.path?.bridge().deletingLastPathComponent).map(configuration(forDirectory:)) ?? self
    }

    private func configuration(forDirectory directory: String) -> Configuration {
        // If the configuration was explicitly specified via the `--config` param, don't use nested configs
        guard !basedOnCustomConfigurationFiles else { return self }

        let directoryNSString = directory.bridge()
        let configurationSearchPath = directoryNSString.appendingPathComponent(Self.defaultFileName)
        let cacheIdentifier = "nestedPath" + rootDirectory + configurationSearchPath

        if Self.getIsNestedConfigurationSelf(forIdentifier: cacheIdentifier) == true {
            return self
        } else if let cached = Self.getCached(forIdentifier: cacheIdentifier) {
            return cached
        } else {
            var config: Configuration

            if directory == rootDirectory {
                // Use self if at level self
                config = self
            } else if
                FileManager.default.fileExists(atPath: configurationSearchPath),
                !fileGraph.includesFile(atPath: configurationSearchPath)
            {
                // Use self merged with the nested config that was found
                // iff that nested config has not already been used to build the main config

                // Ignore parent_config / child_config specifications of nested configs
                var childConfiguration = Configuration(
                    configurationFiles: [configurationSearchPath],
                    ignoreParentAndChildConfigs: true
                )
                childConfiguration.fileGraph = FileGraph(rootDirectory: directory)
                config = merged(withChild: childConfiguration, rootDirectory: rootDirectory)

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
                Self.setIsNestedConfigurationSelf(forIdentifier: cacheIdentifier, value: true)
            }

            return config
        }
    }
}
