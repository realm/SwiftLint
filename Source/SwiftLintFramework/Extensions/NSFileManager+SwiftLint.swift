//
//  NSFileManager+SwiftLint.swift
//  SwiftLint
//
//  Created by JP Simard on 5/28/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation

public protocol LintableFileManager {
    func filesToLintAtPath(_ path: String, rootDirectory: String?) -> [String]
}

extension FileManager: LintableFileManager {
    public func filesToLintAtPath(_ path: String, rootDirectory: String? = nil) -> [String] {
        let rootPath = rootDirectory ?? currentDirectoryPath
        let absolutePath = path.bridge()
            .absolutePathRepresentation(rootDirectory: rootPath).bridge()
            .standardizingPath
        var isDirectoryObjC: ObjCBool = false
        guard fileExists(atPath: absolutePath, isDirectory: &isDirectoryObjC) else {
            return []
        }
        #if os(Linux)
        let isDirectory = isDirectoryObjC
        #else
        let isDirectory = isDirectoryObjC.boolValue
        #endif
        if isDirectory {
            do {
                return try subpathsOfDirectory(atPath: absolutePath)
                    .map(absolutePath.bridge().appendingPathComponent).filter {
                        $0.bridge().isSwiftFile()
                    }
            } catch {
                fatalError("Couldn't find files in \(absolutePath): \(error)")
            }
        } else if absolutePath.bridge().isSwiftFile() {
            return [absolutePath]
        }
        return []
    }
}
