import Foundation

extension Configuration {
    // MARK: Lintable Paths

    /// Returns the files that can be linted by SwiftLint in the specified parent path.
    ///
    /// - parameter path:            The parent path in which to search for lintable files. Can be a directory or a
    ///                              file.
    /// - parameter forceExclude:    Whether or not excludes defined in this configuration should be applied even if
    ///                              `path` is an exact match.
    /// - parameter excludeByPrefix: Whether or not it uses the exclude-by-prefix algorithm.
    ///
    /// - returns: Files to lint.
    public func lintableFiles(inPath path: String,
                              forceExclude: Bool,
                              excludeByPrefix: Bool) -> [SwiftLintFile] {
        lintablePaths(inPath: path, forceExclude: forceExclude, excludeByPrefix: excludeByPrefix)
            .compactMap(SwiftLintFile.init(pathDeferringReading:))
    }

    /// Returns the paths for files that can be linted by SwiftLint in the specified parent path.
    ///
    /// - parameter path:            The parent path in which to search for lintable files. Can be a directory or a
    ///                              file.
    /// - parameter forceExclude:    Whether or not excludes defined in this configuration should be applied even if
    ///                              `path` is an exact match.
    /// - parameter excludeByPrefix: Whether or not it uses the exclude-by-prefix algorithm.
    /// - parameter fileManager:     The lintable file manager to use to search for lintable files.
    ///
    /// - returns: Paths for files to lint.
    internal func lintablePaths(
        inPath path: String,
        forceExclude: Bool,
        excludeByPrefix: Bool,
        fileManager: some LintableFileManager = FileManager.default
    ) -> [String] {
        if fileManager.isFile(atPath: path) {
            if forceExclude {
                return excludeByPrefix
                    ? filterExcludedPathsByPrefix(in: [path.absolutePathStandardized()])
                    : filterExcludedPaths(in: [path.absolutePathStandardized()])
            }
            // If path is a file and we're not forcing excludes, skip filtering with excluded/included paths
            return [path]
        }

        let pathsForPath = includedPaths.isEmpty ? fileManager.filesToLint(inPath: path, rootDirectory: nil) : []
        let includedPaths = self.includedPaths
            .flatMap(Glob.resolveGlob)
            .parallelFlatMap { fileManager.filesToLint(inPath: $0, rootDirectory: rootDirectory) }

        return excludeByPrefix
            ? filterExcludedPathsByPrefix(in: pathsForPath, includedPaths)
            : filterExcludedPaths(in: pathsForPath, includedPaths)
    }

    /// Returns an array of file paths after removing the excluded paths as defined by this configuration.
    ///
    /// - parameter paths: The input paths to filter.
    ///
    /// - returns: The input paths after removing the excluded paths.
    public func filterExcludedPaths(in paths: [String]...) -> [String] {
        let exclusionPatterns = self.excludedPaths.compactMap { Glob.toRegex($0, rootPath: rootDirectory) }
        let pathsWithoutExclusions = paths
            .flatMap { $0 }
            .filter { path in !exclusionPatterns.contains { $0.firstMatch(in: path, range: path.fullNSRange) != nil } }
        return pathsWithoutExclusions.unique
    }

    /// Returns the file paths that are excluded by this configuration using filtering by absolute path prefix.
    ///
    /// For cases when excluded directories contain many lintable files (e. g. Pods) it works faster than default
    /// algorithm `filterExcludedPaths`.
    ///
    /// - returns: The input paths after removing the excluded paths.
    public func filterExcludedPathsByPrefix(in paths: [String]...) -> [String] {
        let allPaths = paths.flatMap { $0 }
        let excludedPaths = self.excludedPaths
            .parallelFlatMap { @Sendable in Glob.resolveGlob($0) }
            .map { $0.absolutePathStandardized() }
        return allPaths.filter { path in
            !excludedPaths.contains { path.hasPrefix($0) }
        }
    }
}
