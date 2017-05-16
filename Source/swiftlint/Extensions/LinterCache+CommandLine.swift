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

        return (try? LinterCache(contentsOf: url)) ?? LinterCache()
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
