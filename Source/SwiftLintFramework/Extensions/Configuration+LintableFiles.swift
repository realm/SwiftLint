//
//  Configuration+LintableFiles.swift
//  SwiftLint
//
//  Created by JP Simard on 7/17/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

extension Configuration {
    public func lintableFiles(inPath path: String) -> [File] {
        return lintablePaths(inPath: path).flatMap(File.init(path:))
    }

    public func lintableFiles(ofFiles files: [File]) -> [File] {
        let excludedPaths = excluded.flatMap {
            FileManager.default.filesToLint(inPath: $0, rootDirectory: rootPath)
        }
        return files.filter {
            guard let path = $0.path else {
                return true
            }
            return !excludedPaths.contains(path)
        }
    }

    internal func lintablePaths(inPath path: String,
                                fileManager: LintableFileManager = FileManager.default) -> [String] {
        // If path is a file, skip filtering with excluded/included paths
        if path.isFile {
            return [path]
        }
        let pathsForPath = included.isEmpty ? fileManager.filesToLint(inPath: path, rootDirectory: nil) : []
        let excludedPaths = excluded.flatMap {
            fileManager.filesToLint(inPath: $0, rootDirectory: rootPath)
        }
        let includedPaths = included.flatMap {
            fileManager.filesToLint(inPath: $0, rootDirectory: rootPath)
        }
        return (pathsForPath + includedPaths).filter {
            !excludedPaths.contains($0)
        }
    }
}
