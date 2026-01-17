import FilenameMatcher
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
    public func lintableFiles(inPath path: URL,
                              forceExclude: Bool,
                              excludeByPrefix: Bool) -> [SwiftLintFile] {
        lintablePaths(inPath: path, forceExclude: forceExclude, excludeByPrefix: excludeByPrefix)
            .parallelCompactMap { SwiftLintFile(pathDeferringReading: $0) }
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
    func lintablePaths(
        inPath path: URL,
        forceExclude: Bool,
        excludeByPrefix: Bool,
        fileManager: some LintableFileManager = FileManager.default
    ) -> [URL] {
        let excluder = createExcluder(excludeByPrefix: excludeByPrefix)

        // Handle single file path.
        if path.isSwiftFile {
            return fileManager.filesToLint(
                inPath: path,
                excluder: forceExclude ? excluder : .noExclusion
            )
        }

        // With no included paths, we lint everything in the given path.
        if includedPaths.isEmpty {
            return makeUnique(paths: fileManager.filesToLint(inPath: path, excluder: excluder))
        }

        // With included paths, only lint them (after resolving globs).
        let pathsToLint = includedPaths
            .flatMap { Glob.resolveGlob($0) }
            .parallelFlatMap {
                fileManager.filesToLint(
                    inPath: $0,
                    excluder: excluder
                )
            }

        // Duplicates may arise, so make them unique.
        return makeUnique(paths: pathsToLint)
    }

    private func makeUnique(paths: [URL]) -> [URL] {
        #if os(macOS)
        let result = NSOrderedSet(array: paths)
        #else
        let result = NSMutableOrderedSet(capacity: paths.count)
        result.addObjects(from: paths)
        #endif
        return result.array as! [URL] // swiftlint:disable:this force_cast
    }

    func filteredPaths(in paths: [URL], excludeByPrefix: Bool) -> [URL] {
        let excluder = createExcluder(excludeByPrefix: excludeByPrefix)
        return paths.filter { !excluder.excludes(path: $0) }
    }

    private func createExcluder(excludeByPrefix: Bool) -> Excluder {
        if excludedPaths.isEmpty {
            return .noExclusion
        }
        if excludeByPrefix {
            return .byPrefix(prefixes: excludedPaths.flatMap(Glob.resolveGlob).map(\.path))
        }
        return .matching(matchers: excludedPaths.flatMap { Glob.createFilenameMatchers(pattern: $0.path) })
    }
}
