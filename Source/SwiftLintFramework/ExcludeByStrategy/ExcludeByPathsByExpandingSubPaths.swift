import Foundation

/// Returns an array of file paths after removing the excluded paths as defined by this configuration.
///
/// - parameter fileManager: The lintable file manager to use to expand the excluded paths into all matching paths.
/// - parameter paths:       The input paths to filter.
///
/// - returns: The input paths after removing the excluded paths.
struct ExcludeByPathsByExpandingSubPaths: ExcludeByStrategy {
    let excludedPaths: [String]

    init(configuration: Configuration, fileManager: some LintableFileManager = FileManager.default) {
        self.excludedPaths = configuration.excludedPaths
            .flatMap(Glob.resolveGlob)
            .parallelFlatMap { fileManager.filesToLint(inPath: $0, rootDirectory: configuration.rootDirectory) }
    }

    init(_ excludedPaths: [String]) {
        self.excludedPaths = excludedPaths
    }

    func filterExcludedPaths(in paths: [String]...) -> [String] {
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
}
