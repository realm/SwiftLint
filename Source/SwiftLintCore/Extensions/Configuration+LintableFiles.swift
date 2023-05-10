import Foundation

extension Configuration {
    public enum ExcludeBy {
        case prefix
        case paths(excludedPaths: [String])
    }

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
                              excludeBy: ExcludeBy) -> [SwiftLintFile] {
        return lintablePaths(inPath: path, forceExclude: forceExclude, excludeBy: excludeBy)
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
        excludeBy: ExcludeBy,
        fileManager: LintableFileManager = FileManager.default
    ) -> [String] {
        if fileManager.isFile(atPath: path) {
            if forceExclude {
                switch excludeBy {
                case .prefix:
                    return filterExcludedPathsByPrefix(in: [path.absolutePathStandardized()])
                case .paths(let excludedPaths):
                    return filterExcludedPaths(excludedPaths, in: [path.absolutePathStandardized()])
                }
            }
            // If path is a file and we're not forcing excludes, skip filtering with excluded/included paths
            return [path]
        }

        let pathsForPath = includedPaths.isEmpty ? fileManager.filesToLint(inPath: path, rootDirectory: nil) : []
        let includedPaths = self.includedPaths
            .flatMap(Glob.resolveGlob)
            .parallelFlatMap { fileManager.filesToLint(inPath: $0, rootDirectory: rootDirectory) }

        switch excludeBy {
        case .prefix:
            return filterExcludedPathsByPrefix(in: pathsForPath, includedPaths)
        case .paths(let excludedPaths):
            return filterExcludedPaths(excludedPaths, in: pathsForPath, includedPaths)
        }
    }

    /// Returns an array of file paths after removing the excluded paths as defined by this configuration.
    ///
    /// - parameter fileManager: The lintable file manager to use to expand the excluded paths into all matching paths.
    /// - parameter paths:       The input paths to filter.
    ///
    /// - returns: The input paths after removing the excluded paths.
    public func filterExcludedPaths(
        _ excludedPaths: [String],
        in paths: [String]...
    ) -> [String] {
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
    public func excludedPaths(fileManager: LintableFileManager = FileManager.default) -> [String] {
        return excludedPaths
            .flatMap(Glob.resolveGlob)
            .parallelFlatMap { fileManager.filesToLint(inPath: $0, rootDirectory: rootDirectory) }
    }
}
