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
        guard let url = cacheUrl(options: options, configuration: configuration) else {
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
        if let url = cacheUrl(options: options, configuration: configuration) {
            try? save(to: url)
        }
    }

}

private func cacheUrl(options: LintOptions, configuration: Configuration) -> URL? {
    guard !options.ignoreCache else {
        return nil
    }
    let path = (options.cachePath.isEmpty ? configuration.cachePath : options.cachePath) ?? ".swiftlint_cache.json"
    return URL(fileURLWithPath: path)
}
