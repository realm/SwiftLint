import Foundation

extension Configuration {
    public func lintableFiles(inPath path: String, forceExclude: Bool) -> [SwiftLintFile] {
        return lintablePaths(inPath: path, forceExclude: forceExclude)
            .compactMap(SwiftLintFile.init(pathDeferringReading:))
    }

    internal func lintablePaths(inPath path: String, forceExclude: Bool,
                                fileManager: LintableFileManager = FileManager.default) -> [String] {
        // If path is a file and we're not forcing excludes, skip filtering with excluded/included paths
        if path.isFile && !forceExclude {
            return [path]
        }
        let pathsForPath = included.isEmpty ? fileManager.filesToLint(inPath: path, rootDirectory: nil) : []
        let includedPaths = included.parallelFlatMap {
            fileManager.filesToLint(inPath: $0, rootDirectory: self.rootPath)
        }
        return filterExcludedPaths(fileManager: fileManager, in: pathsForPath, includedPaths)
    }
}

extension Configuration {
    public func filterExcludedPaths(fileManager: LintableFileManager = FileManager.default,
                                    in paths: [String]...) -> [String] {
        let allPaths = paths.flatMap { $0 }
#if os(Linux)
        let result = NSMutableOrderedSet(capacity: allPaths.count)
        result.addObjects(from: allPaths)
#else
        let result = NSMutableOrderedSet(array: allPaths)
#endif
        let excludedPaths = self.excludedPaths(fileManager: fileManager)
        result.minusSet(Set(excludedPaths))
        // swiftlint:disable:next force_cast
        return result.map { $0 as! String }
    }

    internal func excludedPaths(fileManager: LintableFileManager) -> [String] {
        return excluded
            .flatMap(Glob.resolveGlob)
            .parallelFlatMap {
                fileManager.filesToLint(inPath: $0, rootDirectory: self.rootPath)
            }
    }
}
