//
//  NSFileManager+SwiftLint.swift
//  SwiftLint
//
//  Created by JP Simard on 5/28/15.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Foundation

extension NSFileManager {
    public func allFilesRecursively(directory directory: String) -> [String] {
        return try! subpathsOfDirectoryAtPath(directory)
            .map((directory as NSString).stringByAppendingPathComponent)
    }
}
