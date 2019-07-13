import Foundation
import SourceKittenFramework

extension Configuration {
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
        if
            configurationSearchPath != configurationPath
            && FileManager.default.fileExists(atPath: configurationSearchPath)
        {
            let fullPath = pathNSString.absolutePathRepresentation()
            let config = Configuration.getCached(atPath: fullPath) ??
                Configuration(
                    path: configurationSearchPath,
                    rootPath: fullPath,
                    optional: false,
                    quiet: true
                )
            return merged(with: config)
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

    func mergedIncludedAndExcluded(with configuration: Configuration) -> (included: [String], excluded: [String]) {
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
            rootPath: configuration.rootPath,
            indentation: configuration.indentation
        )
    }
}
