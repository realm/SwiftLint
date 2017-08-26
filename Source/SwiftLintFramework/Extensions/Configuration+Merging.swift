//
//  Configuration+Merging.swift
//  SwiftLint
//
//  Created by JP Simard on 7/17/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

extension Configuration {
    public func configuration(for file: File) -> Configuration {
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
            let config = Configuration.getCached(atPath: fullPath) ??
                Configuration(path: configurationSearchPath, rootPath: fullPath, optional: false, quiet: true)
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

        let isDirectory: Bool
        #if os(Linux)
            isDirectory = isDirectoryObjC
        #else
            isDirectory = isDirectoryObjC.boolValue
        #endif

        if isDirectory {
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

        fileprivate var hashValue: Int {
            return type(of: rule).description.identifier.hashValue
        }
    }

    private func mergingRules(with configuration: Configuration) -> [Rule] {
        switch configuration.rulesMode {
        case .allEnabled:
            // Technically not possible yet as it's not configurable in a .swiftlint.yml file,
            // but implemented for completeness
            return configuration.rules
        case .whitelisted(let whitelistedRules):
            // Use an intermediate set to filter out duplicate rules when merging configurations
            // (always use the nested rule first if it exists)
            return Set(configuration.rules.map(HashableRule.init))
                .union(rules.map(HashableRule.init))
                .map { $0.rule }
                .filter { rule in
                    return whitelistedRules.contains(type(of: rule).description.identifier)
                }
        case let .default(disabled, optIn):
            // Same here
            return Set(
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
            rootPath: configuration.rootPath
        )
    }
}
