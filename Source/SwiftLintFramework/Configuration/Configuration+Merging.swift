import Foundation
import SourceKittenFramework

/// GENERAL NOTE ON MERGING: The child configuration is added on top of the parent configuration
/// and is preferred in case of conflicts!

extension Configuration {
    // MARK: - Methods: Merging
    package func merged(
        withChild childConfiguration: Configuration,
        rootDirectory: URL = URL.cwd
    ) -> Configuration {
        let mergedIncludedAndExcluded = mergedIncludedAndExcluded(with: childConfiguration)

        var mergedConfiguration = Configuration(
            rulesWrapper: rulesWrapper.merged(with: childConfiguration.rulesWrapper),
            fileGraph: FileGraph(rootDirectory: rootDirectory),
            includedPaths: mergedIncludedAndExcluded.includedPaths,
            excludedPaths: mergedIncludedAndExcluded.excludedPaths,
            indentation: mergedScalarValue(for: .indentation, from: childConfiguration, keyPath: \.indentation),
            warningThreshold: mergedWarningTreshold(with: childConfiguration),
            reporter: reporter,
            cachePath: cachePath,
            allowZeroLintableFiles: mergedScalarValue(
                for: .allowZeroLintableFiles,
                from: childConfiguration,
                keyPath: \.allowZeroLintableFiles
            ),
            strict: mergedScalarValue(for: .strict, from: childConfiguration, keyPath: \.strict),
            lenient: mergedScalarValue(for: .lenient, from: childConfiguration, keyPath: \.lenient),
            baseline: mergedScalarValue(for: .baseline, from: childConfiguration, keyPath: \.baseline),
            writeBaseline: mergedScalarValue(
                for: .writeBaseline,
                from: childConfiguration,
                keyPath: \.writeBaseline
            ),
            checkForUpdates: mergedScalarValue(
                for: .checkForUpdates,
                from: childConfiguration,
                keyPath: \.checkForUpdates
            )
        )
        mergedConfiguration.explicitlyConfiguredKeys =
            mergedExplicitlyConfiguredKeys(with: childConfiguration)
        return mergedConfiguration
    }

    private func mergedExplicitlyConfiguredKeys(
        with childConfiguration: Configuration
    ) -> Set<Key>? {
        guard let parentKeys = explicitlyConfiguredKeys,
              let childKeys = childConfiguration.explicitlyConfiguredKeys else {
            return nil
        }
        return parentKeys.union(childKeys)
    }

    private func mergedScalarValue<Value>(
        for key: Key,
        from childConfiguration: Configuration,
        keyPath: KeyPath<Configuration, Value>
    ) -> Value {
        guard let explicitlyConfiguredKeys = childConfiguration.explicitlyConfiguredKeys else {
            return childConfiguration[keyPath: keyPath]
        }

        return explicitlyConfiguredKeys.contains(key)
            ? childConfiguration[keyPath: keyPath]
            : self[keyPath: keyPath]
    }

    private func mergedIncludedAndExcluded(
        with childConfiguration: Configuration
    ) -> (includedPaths: [URL], excludedPaths: [URL]) {
        let childConfigIncluded = childConfiguration.includedPaths
        let childConfigExcluded = childConfiguration.excludedPaths

        // Prefer child configuration over parent configuration
        let includedPaths = includedPaths.filter { includePath in
            !childConfigExcluded.contains(includePath)
        }
        let excludedPaths = excludedPaths.filter { excludePath in
            !childConfigIncluded.contains(excludePath)
        }

        return (
            includedPaths: includedPaths + childConfigIncluded,
            excludedPaths: excludedPaths + childConfigExcluded
        )
    }

    private func mergedWarningTreshold(
        with childConfiguration: Configuration
    ) -> Int? {
        if let parentWarningTreshold = warningThreshold {
            if let childWarningTreshold = childConfiguration.warningThreshold {
                return min(childWarningTreshold, parentWarningTreshold)
            }
            return parentWarningTreshold
        }
        return childConfiguration.warningThreshold
    }

    // MARK: Accessing File Configurations
    /// Returns a new configuration that applies to the specified file by merging the current configuration with any
    /// nested configurations in the directory inheritance graph present until the level of the specified file.
    ///
    /// - parameter file: The file for which to obtain a configuration value.
    ///
    /// - returns: A new configuration.
    public func configuration(for file: SwiftLintFile) -> Configuration {
        (file.path?.deletingLastPathComponent()).map(configuration(forDirectory:)) ?? self
    }

    private func configuration(forDirectory directory: URL) -> Configuration {
        // If the configuration was explicitly specified via the `--config` param, don't use nested configs
        guard !basedOnCustomConfigurationFiles else { return self }

        let configurationSearchPath = directory.appending(path: Self.defaultFileName, directoryHint: .notDirectory)
        let cacheIdentifier = "nestedPath" + rootDirectory.path + configurationSearchPath.path

        if Self.getIsNestedConfigurationSelf(forIdentifier: cacheIdentifier) == true {
            return self
        }
        if let cached = Self.getCached(forIdentifier: cacheIdentifier) {
            return cached
        }
        var config: Configuration

        if directory == rootDirectory {
            // Use self if at level self
            config = self
        } else if configurationSearchPath.exists, !fileGraph.includesFile(atPath: configurationSearchPath) {
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
        } else if directory.path != "/" {
            // If we are not at the root path, continue down the tree
            config = configuration(forDirectory: directory.deletingLastPathComponent())
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
