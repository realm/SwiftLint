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
            fileGraph: childConfiguration.rootDirectory.map(FileGraph.init(rootDirectory:)),
            includedPaths: mergedIncludedAndExcluded.included,
            excludedPaths: mergedIncludedAndExcluded.excluded,
            indentation: childConfiguration.indentation,
            warningThreshold: mergedWarningTreshold(with: childConfiguration),
            reporter: reporter,
            cachePath: cachePath,
            allowZeroLintableFiles: childConfiguration.allowZeroLintableFiles
        )
    }

    private func mergedIncludedAndExcluded(
        with childConfiguration: Configuration
    ) -> (included: [String], excluded: [String]) {
        let parentRootPathComps = rootDirectory?.components(separatedBy: "/") ?? []
        var childRootPathComps = childConfiguration.rootDirectory?.components(separatedBy: "/") ?? []

        let parentConfigIncluded: [String]
        let parentConfigExcluded: [String]
        let childConfigIncluded: [String] = childConfiguration.includedPaths
        let childConfigExcluded: [String] = childConfiguration.excludedPaths

        if parentRootPathComps == childRootPathComps {
            // If we are on the on same level, things are quite easy
            parentConfigIncluded = includedPaths
            parentConfigExcluded = excludedPaths
        } else {
            // Safeguard whether child is actually child (should always be the case)
            guard childRootPathComps.starts(with: parentRootPathComps) else {
                return (included: childConfigIncluded, excluded: childConfigExcluded)
            }

            childRootPathComps.removeFirst(parentRootPathComps.count)

            // Get parent paths relative to child root directory; filter out irrelevant paths
            func process(parentPaths: [String]) -> [String] {
                return parentPaths.filter {
                    $0.components(separatedBy: "/").starts(with: childRootPathComps)
                }.map {
                    var pathComponents = $0.components(separatedBy: "/")
                    pathComponents.removeFirst(childRootPathComps.count)
                    return pathComponents.joined(separator: "/")
                }
            }

            parentConfigIncluded = process(parentPaths: includedPaths)
            parentConfigExcluded = process(parentPaths: excludedPaths)
        }

        // Prefer child configuration over parent configuration
        return (
            included: parentConfigIncluded.filter { !childConfigExcluded.contains($0) } + childConfigIncluded,
            excluded: parentConfigExcluded.filter { !childConfigIncluded.contains($0) } + childConfigExcluded
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
