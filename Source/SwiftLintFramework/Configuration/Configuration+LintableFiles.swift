import Foundation

extension Configuration {
    // MARK: Lintable Paths
    /// Returns the files that can be linted by SwiftLint in the specified parent path.
    ///
    /// - parameter path:            The parent path in which to search for lintable files. Can be a directory or a
    ///                              file.
    /// - parameter forceExclude:    Whether or not excludes defined in this configuration should be applied even if
    ///                              `path` is an exact match.
    /// - parameter excludeByPrefix: Whether or not uses excluding by prefix algorithm.
    ///
    /// - returns: Files to lint.
    public func lintableFiles(inPath path: String,
                              forceExclude: Bool,
                              excludeBy: some ExcludeByStrategy) -> [SwiftLintFile] {
        lintablePaths(inPath: path, forceExclude: forceExclude, excludeBy: excludeBy)
            .parallelCompactMap {
                SwiftLintFile(pathDeferringReading: $0)
            }
    }

    /// Returns the paths for files that can be linted by SwiftLint in the specified parent path.
    ///
    /// - parameter path:            The parent path in which to search for lintable files. Can be a directory or a
    ///                              file.
    /// - parameter forceExclude:    Whether or not excludes defined in this configuration should be applied even if
    ///                              `path` is an exact match.
    /// - parameter excludeByPrefix: Whether or not uses excluding by prefix algorithm.
    /// - parameter fileManager:     The lintable file manager to use to search for lintable files.
    ///
    /// - returns: Paths for files to lint.
    internal func lintablePaths(
        inPath path: String,
        forceExclude: Bool,
        excludeBy: any ExcludeByStrategy,
        fileManager: some LintableFileManager = FileManager.default
    ) -> [String] {
        if fileManager.isFile(atPath: path) {
            if forceExclude {
                return excludeBy.filterExcludedPaths(in: [path.absolutePathStandardized()])
            }
            // If path is a file and we're not forcing excludes, skip filtering with excluded/included paths
            return [path]
        }

        let pathsForPath = includedPaths.isEmpty ? fileManager.filesToLint(inPath: path, rootDirectory: nil) : []
        let includedPaths = self.includedPaths
            .flatMap(Glob.resolveGlob)
            .parallelFlatMap { fileManager.filesToLint(inPath: $0, rootDirectory: rootDirectory) }

        return excludeBy.filterExcludedPaths(in: pathsForPath, includedPaths)
    }
}
