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
    public func lintableFiles(inPath path: String, forceExclude: Bool,
                              excludeByPrefix: Bool = false) -> [SwiftLintFile] {
        return lintablePaths(inPath: path, forceExclude: forceExclude, excludeByPrefix: excludeByPrefix)
            .compactMap(SwiftLintFile.init(pathDeferringReading:))
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
        excludeByPrefix: Bool = false,
        fileManager: LintableFileManager = FileManager.default
    ) -> [String] {
        if path.isFile {
            if forceExclude {
                return excludeByPrefix
                    ? filterExcludedPathsByPrefix(in: [path.absolutePathStandardized()])
                    : filterExcludedPaths(fileManager: fileManager, in: [path.absolutePathStandardized()])
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
            : filterExcludedPaths(fileManager: fileManager, in: pathsForPath, includedPaths)
    }

    /// Returns an array of file paths after removing the excluded paths as defined by this configuration.
    ///
    /// - parameter fileManager: The lintable file manager to use to expand the excluded paths into all matching paths.
    /// - parameter paths:       The input paths to filter.
    ///
    /// - returns: The input paths after removing the excluded paths.
    public func filterExcludedPaths(
        fileManager: LintableFileManager = FileManager.default,
        in paths: [String]...
    ) -> [String] {
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

    /// Returns the file paths that are excluded by this configuration using filtering by absolute path prefix.
    ///
    /// For cases when excluded directories contain many lintable files (e. g. Pods) it works faster than default
    /// algorithm `filterExcludedPaths`.
    ///
    /// - returns: The input paths after removing the excluded paths.
    public func filterExcludedPathsByPrefix(in paths: [String]...) -> [String] {
        let allPaths = paths.flatMap { $0 }
        let excludedPaths = self.excludedPaths.parallelFlatMap(transform: Glob.resolveGlob)
                                    .map { $0.absolutePathStandardized() }
        return allPaths.filter { path in
            !excludedPaths.contains { path.hasPrefix($0) }
        }
    }

    /// Returns the file paths that are excluded by this configuration after expanding them using the specified file
    /// manager.
    ///
    /// - parameter fileManager: The file manager to get child paths in a given parent location.
    ///
    /// - returns: The expanded excluded file paths.
    private func excludedPaths(fileManager: LintableFileManager) -> [String] {
        return excludedPaths
            .flatMap(Glob.resolveGlob)
            .parallelFlatMap { fileManager.filesToLint(inPath: $0, rootDirectory: rootDirectory) }
    }
}
