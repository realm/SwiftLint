//
//  NSFileManager+SwiftLint.swift
//  SwiftLint
//
//  Created by JP Simard on 5/28/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation

public protocol LintableFileManager {
    func filesToLint(inPath: String, rootDirectory: String?) -> [String]
    func modificationDate(forFileAtPath: String) -> Date?
}

extension FileManager: LintableFileManager {
    public func filesToLint(inPath path: String, rootDirectory: String? = nil) -> [String] {
        let rootPath = rootDirectory ?? currentDirectoryPath
        let absolutePath = path.bridge()
            .absolutePathRepresentation(rootDirectory: rootPath).bridge()
            .standardizingPath

        // if path is a file, it won't be returned in `enumerator(atPath:)`
        if absolutePath.bridge().isSwiftFile() && absolutePath.isFile {
            return [absolutePath]
        }

        return enumerator(atPath: absolutePath)?.flatMap { element -> String? in
            if let element = element as? String, element.bridge().isSwiftFile() {
                return absolutePath.bridge().appendingPathComponent(element)
            }
            return nil
        } ?? []
    }

    public func modificationDate(forFileAtPath path: String) -> Date? {
        return (try? attributesOfItem(atPath: path))?[.modificationDate] as? Date
    }
}
