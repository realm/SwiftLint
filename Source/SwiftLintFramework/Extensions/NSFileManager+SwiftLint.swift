//
//  NSFileManager+SwiftLint.swift
//  SwiftLint
//
//  Created by JP Simard on 5/28/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation

extension FileManager {
    internal func filesToLintAtPath(_ path: String, rootDirectory: String? = nil) -> [String] {
        let rootPath = rootDirectory ?? currentDirectoryPath
        let absolutePath = (path.absolutePathRepresentation(rootDirectory: rootPath) as NSString)
            .standardizingPath
        var isDirectory: ObjCBool = false
        guard fileExists(atPath: absolutePath, isDirectory: &isDirectory) else {
            return []
        }
        if isDirectory.boolValue {
            do {
                return try subpathsOfDirectory(atPath: absolutePath)
                    .map((absolutePath as NSString).appendingPathComponent).filter {
                        $0.isSwiftFile()
                }
            } catch {
                fatalError("Couldn't find files in \(absolutePath): \(error)")
            }
        } else if absolutePath.isSwiftFile() {
            return [absolutePath]
        }
        return []
    }
}
