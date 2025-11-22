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
    public func lintableFiles(inPath path: String,
                              forceExclude: Bool,
                              excludeByPrefix: Bool) -> [SwiftLintFile] {
        lintablePaths(inPath: path, forceExclude: forceExclude, excludeByPrefix: excludeByPrefix)
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
    /// - parameter excludeByPrefix: Whether or not it uses the exclude-by-prefix algorithm.
    /// - parameter fileManager:     The lintable file manager to use to search for lintable files.
    ///
    /// - returns: Paths for files to lint.
    func lintablePaths(
        inPath path: String,
        forceExclude: Bool,
        excludeByPrefix: Bool,
        fileManager: some LintableFileManager = FileManager.default
    ) -> [String] {
        let excluder = createExcluder(excludeByPrefix: excludeByPrefix)

        // Handle single file path.
        if fileManager.isFile(atPath: path) {
            return fileManager.filesToLint(
                inPath: path,
                rootDirectory: nil,
                excluder: forceExclude ? excluder : .noExclusion
            )
        }

        // With no included paths, we lint everything in the given path.
        if includedPaths.isEmpty {
            return fileManager.filesToLint(
                inPath: path,
                rootDirectory: nil,
                excluder: excluder
            )
        }

        // With included paths, we only lint those paths (after resolving globs).
        return includedPaths
            .flatMap(Glob.resolveGlob)
            .parallelFlatMap {
                fileManager.filesToLint(
                    inPath: $0,
                    rootDirectory: rootDirectory,
                    excluder: excluder
                )
            }
    }

    func filteredPaths(in paths: [String], excludeByPrefix: Bool) -> [String] {
        let excluder = createExcluder(excludeByPrefix: excludeByPrefix)
        return paths.filter { !excluder.excludes(path: $0) }
    }

    private func createExcluder(excludeByPrefix: Bool) -> Excluder {
        if excludeByPrefix {
            return .byPrefix(
                prefixes: self.excludedPaths
                    .flatMap { Glob.resolveGlob($0) }
                    .map { $0.absolutePathStandardized() }
              )
        }
        return .matching(
            matchers: self.excludedPaths.flatMap {
                Glob.createFilenameMatchers(root: rootDirectory, pattern: $0)
            }
        )
    }
}
