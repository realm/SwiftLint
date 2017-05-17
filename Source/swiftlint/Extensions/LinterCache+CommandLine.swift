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

    internal class func makeCache(options: LintOptions, configuration: Configuration) -> LinterCache {
        let url = cacheURL(options: options, configuration: configuration)
        return (try? LinterCache(contentsOf: url)) ?? LinterCache()
    }

    internal func save(options: LintOptions, configuration: Configuration) {
        try? save(to: cacheURL(options: options, configuration: configuration))
    }

}

private func cacheURL(options: LintOptions, configuration: Configuration) -> URL {
    let baseURL: URL
    if let path = options.cachePath.isEmpty ? configuration.cachePath : options.cachePath {
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

    let rootPath = options.path.bridge().absolutePathRepresentation()
    return folder.appendingPathComponent("\(rootPath.hash).json")
}
