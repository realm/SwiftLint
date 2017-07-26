//
//  Configuration+LintableFiles.swift
//  SwiftLint
//
//  Created by JP Simard on 7/17/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import Glob
import SourceKittenFramework

extension Configuration {
    public func lintableFiles(inPath path: String) -> [File] {
        return lintablePaths(inPath: path).flatMap(File.init(path:))
    }

    internal func lintablePaths(inPath path: String,
                                fileManager: LintableFileManager = FileManager.default) -> [String] {
        // If path is a Swift file, skip filtering with excluded/included paths
        if path.bridge().isSwiftFile() && path.isFile {
            return [path]
        }
        let pathsForPath = included.isEmpty ? fileManager.filesToLint(inPath: path, rootDirectory: nil) : []
        let excludedPaths = excluded.flatMap { excludedPath -> [String] in
            if excludedPath.containsWildcards {
                return Glob.filesToLint(inPath: excludedPath, rootDirectory: rootPath)
            } else {
                return fileManager.filesToLint(inPath: excludedPath, rootDirectory: rootPath)
            }
        }
        let includedPaths = included.flatMap {
            fileManager.filesToLint(inPath: $0, rootDirectory: rootPath)
        }
        return (pathsForPath + includedPaths).filter({ !excludedPaths.contains($0) })
    }
}
