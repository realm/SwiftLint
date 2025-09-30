/// Returns the file paths that are excluded by this configuration using filtering by absolute path prefix.
///
/// For cases when excluded directories contain many lintable files (e. g. Pods) it works faster than default
/// algorithm `filterExcludedPaths`.
///
/// - returns: The input paths after removing the excluded paths.
struct ExcludeByPrefixStrategy: ExcludeByStrategy {
    let excludedPaths: [String]

    func filterExcludedPaths(in paths: [String]...) -> [String] {
        let allPaths = paths.flatMap { $0 }
        let excludedPaths = self.excludedPaths
            .parallelFlatMap { @Sendable in Glob.resolveGlob($0) }
            .map { $0.absolutePathStandardized() }
        return allPaths.filter { path in
            !excludedPaths.contains { path.hasPrefix($0) }
        }
    }
}
