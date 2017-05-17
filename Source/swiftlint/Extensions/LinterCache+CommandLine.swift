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

    internal class func makeCache(configuration: Configuration) -> LinterCache {
        return (try? LinterCache(contentsOf: cacheURL(configuration: configuration))) ?? LinterCache()
    }

    internal func save(configuration: Configuration) {
        try? save(to: cacheURL(configuration: configuration))
    }

}

private func cacheURL(configuration: Configuration) -> URL {
    let baseURL: URL
    if let path = configuration.cachePath {
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
