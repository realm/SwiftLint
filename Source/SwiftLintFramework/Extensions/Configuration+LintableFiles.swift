import Foundation

extension Configuration {
    /// Returns the files that can be linted by SwiftLint in the specified parent path.
    ///
    /// - parameter path:         The parent path in which to search for lintable files. Can be a directory or a file.
    /// - parameter forceExclude: Whether or not excludes defined in this configuration should be applied even if `path`
    ///                           is an exact match.
    ///
    /// - returns: Files to lint.
    public func lintableFiles(inPath path: String, forceExclude: Bool) -> [SwiftLintFile] {
        return lintablePaths(inPath: path, forceExclude: forceExclude)
            .compactMap(SwiftLintFile.init(pathDeferringReading:))
    }

    /// Returns the paths for files that can be linted by SwiftLint in the specified parent path.
    ///
    /// - parameter path:         The parent path in which to search for lintable files. Can be a directory or a file.
    /// - parameter forceExclude: Whether or not excludes defined in this configuration should be applied even if `path`
    ///                           is an exact match.
    /// - parameter fileManager:  The lintable file manager to use to search for lintable files.
    ///
    /// - returns: Paths for files to lint.
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
        return filterExcludedPaths(in: pathsForPath, includedPaths)
    }

    /// Returns an array of file paths after removing the excluded paths as defined by this configuration.
    ///
    /// - parameter paths:       The input paths to filter.
    ///
    /// - returns: The input paths after removing the excluded paths.
    public func filterExcludedPaths(in paths: [String]...) -> [String] {
        let allPaths = paths.flatMap { $0 }
        let excludedPaths = excluded.flatMap(Glob.resolveGlob).map { $0.absolutePathStandardized() }

        return allPaths.filter { path in
            !excludedPaths.contains { path.hasPrefix($0) }
        }
    }
}
