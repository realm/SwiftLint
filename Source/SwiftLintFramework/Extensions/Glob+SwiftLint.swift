//
//  Glob+SwiftLint.swift
//  SwiftLint
//
//  Created by Andrey Ostanin on 29/06/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import Glob

extension Glob {
    static let globBehavior = Glob.Behavior(supportsGlobstar: true,
                                            includesFilesFromRootOfGlobstar: true,
                                            includesDirectoriesInResults: false,
                                            includesFilesInResultsIfTrailingSlash: false)

    public static func filesToLint(inPath path: String, rootDirectory: String? = nil) -> [String] {
        let rootPath = rootDirectory ?? FileManager.default.currentDirectoryPath
        let absolutePath = path.bridge()
            .absolutePathRepresentation(rootDirectory: rootPath).bridge()
            .standardizingPath
        let glob = Glob(pattern: absolutePath, behavior: globBehavior)
        return glob.flatMap({ $0 })
    }
}
