//
//  LinterCache+CommandLine.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 12/31/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SwiftLintFramework

extension LinterCache {

    class func makeCache(options: LintOptions, configuration: Configuration) -> LinterCache? {
        guard let url = cacheURL(options: options, configuration: configuration) else {
            return nil
        }

        let configurationHash = configuration.hash
        let cache: LinterCache
        do {
            cache = try LinterCache(contentsOf: url, configurationHash: configurationHash)
        } catch {
            cache = LinterCache(configurationHash: configurationHash)
        }

        return cache
    }

    func save(options: LintOptions, configuration: Configuration) {
        if let url = cacheURL(options: options, configuration: configuration) {
            try? save(to: url)
        }
    }

}

private func cacheURL(options: LintOptions, configuration: Configuration) -> URL? {
    guard !options.ignoreCache else {
        return nil
    }

    let path = options.cachePath.isEmpty ? configuration.cachePath : options.cachePath
    return path.map(URL.init(fileURLWithPath:)) ?? defaultCacheURL(options: options)
}

private func defaultCacheURL(options: LintOptions) -> URL {
    let rootPath = options.path.bridge().absolutePathRepresentation()

    #if os(Linux)
        let baseURL = URL(fileURLWithPath: "/var/tmp/")
    #else
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    #endif

    let fileName = String(rootPath.hash) + ".json"
    let folder = baseURL.appendingPathComponent("SwiftLint")

    do {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)
    } catch {
        queuedPrintError("Error while creating cache: " + error.localizedDescription)
    }

    return folder.appendingPathComponent(fileName)
}
