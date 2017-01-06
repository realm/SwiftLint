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
        return enumerator(atPath: absolutePath)?.flatMap { element in
            if let element = element as? String, element.bridge().isSwiftFile() {
                return absolutePath.bridge().appendingPathComponent(element)
            }
            return nil
        } ?? []
    }
}
