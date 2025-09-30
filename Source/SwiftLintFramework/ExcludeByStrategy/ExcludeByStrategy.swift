public protocol ExcludeByStrategy {
    func filterExcludedPaths(in paths: [String]...) -> [String]
}
