import Foundation
import SourceKittenFramework

extension Configuration {
    public func lintableFiles(inPath path: String, forceExclude: Bool) -> [File] {
        return lintablePaths(inPath: path, forceExclude: forceExclude).compactMap(File.init(pathDeferringReading:))
    }

    internal func lintablePaths(inPath path: String, forceExclude: Bool,
                                fileManager: LintableFileManager = FileManager.default) -> [String] {
        // If path is a file and we're not forcing excludes, skip filtering with excluded/included paths
        if path.isFile && !forceExclude {
            return [path]
        }
        let pathsForPath = included.isEmpty ? fileManager.filesToLint(inPath: path, rootDirectory: nil) : []
        let excludedPaths = excluded
            .flatMap(Glob.resolveGlob)
            .parallelFlatMap {
                fileManager.filesToLint(inPath: $0, rootDirectory: self.rootPath)
            }
        let includedPaths = included.parallelFlatMap {
            fileManager.filesToLint(inPath: $0, rootDirectory: self.rootPath)
        }
#if os(Linux)
        let allPaths = pathsForPath + includedPaths
        let result = NSMutableOrderedSet(capacity: allPaths.count)
        result.addObjects(from: allPaths)
#else
        let result = NSMutableOrderedSet(array: pathsForPath + includedPaths)
#endif
        result.minusSet(Set(excludedPaths))
        // swiftlint:disable:next force_cast
        return result.map { $0 as! String }
    }
}
