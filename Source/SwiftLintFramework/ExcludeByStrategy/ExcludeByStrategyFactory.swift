import Foundation

class ExcludeByStrategyFactory {
    static func createExcludeByStrategy(options: LintOrAnalyzeOptions,
                                        configuration: Configuration,
                                        fileManager: some LintableFileManager = FileManager.default)
    -> any ExcludeByStrategy {
        if options.useExcludingByPrefix {
            return ExcludeByPrefixStrategy(excludedPaths: configuration.excludedPaths)
        }

        return ExcludeByPathsByExpandingSubPaths(configuration: configuration, fileManager: fileManager)
    }
}
