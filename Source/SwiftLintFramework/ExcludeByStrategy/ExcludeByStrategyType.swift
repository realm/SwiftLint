import Foundation

enum ExcludeByStrategyType {
    case excludeByPrefix(ExcludeByPrefixStrategy)
    case excludeByPathsByExpandingSubPaths(ExcludeByPathsByExpandingSubPaths)

    static func createExcludeByStrategy(options: LintOrAnalyzeOptions,
                                        configuration: Configuration,
                                        fileManager: some LintableFileManager = FileManager.default)
    -> Self {
        if options.useExcludingByPrefix {
            let strategy = ExcludeByPrefixStrategy(excludedPaths: configuration.excludedPaths)
            return .excludeByPrefix(strategy)
        }

        let strategy = ExcludeByPathsByExpandingSubPaths(configuration: configuration, fileManager: fileManager)
        return .excludeByPathsByExpandingSubPaths(strategy)
    }

    var strategy: any ExcludeByStrategy {
        switch self {
        case .excludeByPrefix(let strategy):
            return strategy
        case .excludeByPathsByExpandingSubPaths(let strategy):
            return strategy
        }
    }
}
