//
//  Configuration+Cache.swift
//  SwiftLint
//
//  Created by JP Simard on 5/22/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

extension Configuration {

    // MARK: Caching Configurations By Path (In-Memory)

    private static var cachedConfigurationsByPath = [String: Configuration]()
    private static var cachedConfigurationsByPathLock = NSLock()

    internal func setCached(atPath path: String) {
        Configuration.cachedConfigurationsByPathLock.lock()
        Configuration.cachedConfigurationsByPath[path] = self
        Configuration.cachedConfigurationsByPathLock.unlock()
    }

    internal static func getCached(atPath path: String) -> Configuration? {
        cachedConfigurationsByPathLock.lock()
        defer { cachedConfigurationsByPathLock.unlock() }
        return cachedConfigurationsByPath[path]
    }

    public func withPrecomputedCacheDescription() -> Configuration {
        var result = self
        result.computedCacheDescription = result.cacheDescription
        return result
    }

    // MARK: SwiftLint Cache (On-Disk)

    internal var cacheDescription: String {
        if let computedCacheDescription = computedCacheDescription {
            return computedCacheDescription
        }

        let cacheRulesDescriptions = rules
            .map { rule in
                return [type(of: rule).description.identifier, rule.cacheDescription]
            }
            .sorted { rule1, rule2 in
                return rule1[0] < rule2[0]
            }
        let jsonObject: [Any] = [
            rootPath ?? FileManager.default.currentDirectoryPath,
            cacheRulesDescriptions
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject),
            let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        queuedFatalError("Could not serialize configuration for cache")
    }

    internal var cacheURL: URL {
        let baseURL: URL
        if let path = cachePath {
            baseURL = URL(fileURLWithPath: path)
        } else {
            #if os(Linux)
                baseURL = URL(fileURLWithPath: "/var/tmp/")
            #else
                baseURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            #endif
        }
        let folder = baseURL.appendingPathComponent("SwiftLint/\(Version.current.value)")

        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)
        } catch {
            queuedPrintError("Error while creating cache: " + error.localizedDescription)
        }

        return folder.appendingPathComponent("cache.json")
    }
}
