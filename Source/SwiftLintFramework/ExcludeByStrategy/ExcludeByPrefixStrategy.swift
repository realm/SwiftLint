//
//  ExcludeByPrefixStrategy.swift
//

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
