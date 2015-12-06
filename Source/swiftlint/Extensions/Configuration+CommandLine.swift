//
//  Configuration+CommandLine.swift
//  SwiftLint
//
//  Created by JP Simard on 12/5/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework
import SwiftLintFramework

extension File {
    private static func maybeSwiftFile(path: String) -> File? {
        if let file = File(path: path) where path.isSwiftFile() {
            return file
        }
        return nil
    }
}

extension Configuration {
    init(commandLinePath: String) {
        self.init(path: commandLinePath, optional: !Process.arguments.contains("--config"))
    }

    func lintableFilesForPath(path: String) -> [File] {
        let pathsForPath = included.isEmpty ? fileManager.filesToLintAtPath(path) : []
        let excludedPaths = excluded.flatMap(fileManager.filesToLintAtPath)
        let includedPaths = included.flatMap(fileManager.filesToLintAtPath)
        let allPaths = pathsForPath.filter(excludedPaths.contains) + includedPaths
        return allPaths.flatMap(File.maybeSwiftFile)
    }
}
