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

    // MARK: SwiftLint Cache (On-Disk)

    internal var cacheDescription: String {
        let cacheRulesDescriptions: [String: Any] = rules.reduce([:]) { accu, element in
            var accu = accu
            accu[type(of: element).description.identifier] = element.cacheDescription
            return accu
        }
        let dict: [String: Any] = [
            "root": rootPath ?? FileManager.default.currentDirectoryPath,
            "rules": cacheRulesDescriptions
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: dict),
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
