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
        if path == rootPath {
            return self
        }

        let pathNSString = path.bridge()
        let configurationSearchPath = pathNSString.appendingPathComponent(Configuration.fileName)

        // If a configuration exists and it isn't us, load and merge the configurations
        if configurationSearchPath != configurationPath &&
            FileManager.default.fileExists(atPath: configurationSearchPath) {
            let fullPath = pathNSString.absolutePathRepresentation()
            let config = Configuration.getCached(atPath: fullPath) ??
                Configuration(path: configurationSearchPath, rootPath: rootPath, optional: false, quiet: true)
            return merge(with: config)
        }

        // If we are not at the root path, continue down the tree
        if path != rootPath && path != "/" {
            return configuration(forPath: pathNSString.deletingLastPathComponent)
        }

        // If nothing else, return self
        return self
    }

    // Currently merge simply overrides the current configuration with the new configuration.
    // This requires that all configuration files be fully specified. In the future this should be
    // improved to do a more intelligent merge allowing for partial nested configurations.
    internal func merge(with configuration: Configuration) -> Configuration {
        return configuration
    }
}
