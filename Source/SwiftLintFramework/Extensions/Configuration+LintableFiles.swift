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
            .flatMap {
                fileManager.filesToLint(inPath: $0, rootDirectory: rootPath)
            }
        let includedPaths = included.flatMap {
            fileManager.filesToLint(inPath: $0, rootDirectory: rootPath)
        }
        let result = NSMutableOrderedSet(array: pathsForPath + includedPaths)
        result.minusSet(Set(excludedPaths))
        return result.map { $0 as! String }
    }
}
