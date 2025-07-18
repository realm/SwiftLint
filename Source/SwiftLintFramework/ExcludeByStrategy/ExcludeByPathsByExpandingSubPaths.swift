//
//  ExcludeByPathsByExpandingSubPaths.swift
//

import Foundation

public struct ExcludeByPathsByExpandingSubPaths: ExcludeByStrategy {
    let excludedPaths: [String]

    public init(configuration: Configuration, fileManager: some LintableFileManager = FileManager.default) {
        self.excludedPaths = configuration.excludedPaths
            .flatMap(Glob.resolveGlob)
            .parallelFlatMap { fileManager.filesToLint(inPath: $0, rootDirectory: configuration.rootDirectory) }
    }

    public init(_ excludedPaths: [String]) {
        self.excludedPaths = excludedPaths
    }

    public func filterExcludedPaths(in paths: [String]...) -> [String] {
        let allPaths = paths.flatMap { $0 }
        #if os(Linux)
        let result = NSMutableOrderedSet(capacity: allPaths.count)
        result.addObjects(from: allPaths)
        #else
        let result = NSMutableOrderedSet(array: allPaths)
        #endif

        result.minusSet(Set(excludedPaths))
        // swiftlint:disable:next force_cast
        return result.map { $0 as! String }
    }
}
