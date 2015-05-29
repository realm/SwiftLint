//
//  NSFileManager+SwiftLint.swift
//  SwiftLint
//
//  Created by JP Simard on 5/28/15.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

extension NSFileManager {
    public func allFilesRecursively(# directory: String) -> [String] {
        let relativeFiles = (contentsOfDirectoryAtPath(directory, error: nil) as? [String] ?? []) +
            (subpathsOfDirectoryAtPath(directory, error: nil) as? [String] ?? [])
        return relativeFiles.map {
            directory.stringByAppendingPathComponent($0)
        }
    }
}
