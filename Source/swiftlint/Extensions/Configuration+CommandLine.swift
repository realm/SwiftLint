import Commandant
import Dispatch
import Foundation
import SourceKittenFramework
import SwiftLintFramework

private let indexIncrementerQueue = DispatchQueue(label: "io.realm.swiftlint.indexIncrementer")

private func scriptInputFiles() -> Result<[SwiftLintFile], CommandantError<()>> {
    func getEnvironmentVariable(_ variable: String) -> Result<String, CommandantError<()>> {
        let environment = ProcessInfo.processInfo.environment
        if let value = environment[variable] {
            return .success(value)
        }
        return .failure(.usageError(description: "Environment variable not set: \(variable)"))
    }

    let count: Result<Int, CommandantError<()>> = {
        let inputFileKey = "SCRIPT_INPUT_FILE_COUNT"
        guard let countString = ProcessInfo.processInfo.environment[inputFileKey] else {
            return .failure(.usageError(description: "\(inputFileKey) variable not set"))
        }
        if let count = Int(countString) {
            return .success(count)
        }
        return .failure(.usageError(description: "\(inputFileKey) did not specify a number"))
    }()

    return count.flatMap { count in
        return .success((0..<count).compactMap { fileNumber in
            switch getEnvironmentVariable("SCRIPT_INPUT_FILE_\(fileNumber)") {
            case let .success(path):
                if path.bridge().isSwiftFile() {
                    return SwiftLintFile(pathDeferringReading: path)
                }
                return nil
            case let .failure(error):
                queuedPrintError(String(describing: error))
                return nil
            }
        })
    }
}

#if os(Linux)
private func autoreleasepool<T>(block: () -> T) -> T { return block() }
#endif

extension Configuration {
    func visitLintableFiles(with visitor: LintableFilesVisitor, storage: RuleStorage)
        -> Result<[SwiftLintFile], CommandantError<()>> {
            return getFiles(with: visitor)
                .flatMap { groupFiles($0, visitor: visitor) }
                .map { linters(for: $0, visitor: visitor) }
                .map { ($0, $0.duplicateFileNames) }
                .map { collect(linters: $0.0, visitor: visitor, storage: storage, duplicateFileNames: $0.1) }
                .map { visit(linters: $0.0, visitor: visitor, storage: storage, duplicateFileNames: $0.1) }
    }

    private func groupFiles(_ files: [SwiftLintFile],
                            visitor: LintableFilesVisitor)
        -> Result<[Configuration: [SwiftLintFile]], CommandantError<()>> {
        if files.isEmpty && !visitor.allowZeroLintableFiles {
            let errorMessage = "No lintable files found at paths: '\(visitor.paths.joined(separator: ", "))'"
            return .failure(.usageError(description: errorMessage))
        }

        var groupedFiles = [Configuration: [SwiftLintFile]]()
        for file in files {
            // Files whose configuration specifies they should be excluded will be skipped
            let fileConfiguration = configuration(for: file)
            let fileConfigurationRootPath = (fileConfiguration.rootPath ?? "").bridge()
            let shouldSkip = fileConfiguration.excluded.contains { excludedRelativePath in
                let excludedPath = fileConfigurationRootPath.appendingPathComponent(excludedRelativePath)
                let filePathComponents = file.path?.bridge().pathComponents ?? []
                let excludedPathComponents = excludedPath.bridge().pathComponents
                return filePathComponents.starts(with: excludedPathComponents)
            }

            if !shouldSkip {
                groupedFiles[fileConfiguration, default: []].append(file)
            }
        }

        return .success(groupedFiles)
    }

    private func outputFilename(for path: String, duplicateFileNames: Set<String>) -> String {
        let basename = path.bridge().lastPathComponent
        if !duplicateFileNames.contains(basename) {
            return basename
        }

        var pathComponents = path.bridge().pathComponents
        let root = self.rootPath ?? FileManager.default.currentDirectoryPath.bridge().standardizingPath
        for component in root.bridge().pathComponents where pathComponents.first == component {
            pathComponents.removeFirst()
        }

        return pathComponents.joined(separator: "/")
    }

    private func linters(for filesPerConfiguration: [Configuration: [SwiftLintFile]],
                         visitor: LintableFilesVisitor) -> [Linter] {
        let fileCount = filesPerConfiguration.reduce(0) { $0 + $1.value.count }

        var linters = [Linter]()
        linters.reserveCapacity(fileCount)
        for (config, files) in filesPerConfiguration {
            let newConfig: Configuration
            if visitor.cache != nil {
                newConfig = config.withPrecomputedCacheDescription()
            } else {
                newConfig = config
            }
            linters += files.map { visitor.linter(forFile: $0, configuration: newConfig) }
        }
        return linters
    }

    private func collect(linters: [Linter],
                         visitor: LintableFilesVisitor,
                         storage: RuleStorage,
                         duplicateFileNames: Set<String>) -> ([CollectedLinter], Set<String>) {
        var collected = 0
        let total = linters.filter({ $0.isCollecting }).count
        let collect = { (linter: Linter) -> CollectedLinter? in
            let skipFile = visitor.shouldSkipFile(atPath: linter.file.path)
            if !visitor.quiet, linter.isCollecting, let filePath = linter.file.path {
                let outputFilename = self.outputFilename(for: filePath, duplicateFileNames: duplicateFileNames)
                let increment = {
                    collected += 1
                    if skipFile {
                        queuedPrintError("""
                            Skipping '\(outputFilename)' (\(collected)/\(total)) \
                            because its compiler arguments could not be found
                            """)
                    } else {
                        queuedPrintError("Collecting '\(outputFilename)' (\(collected)/\(total))")
                    }
                }
                if visitor.parallel {
                    indexIncrementerQueue.sync(execute: increment)
                } else {
                    increment()
                }
            }

            guard !skipFile else {
                return nil
            }

            return autoreleasepool {
                linter.collect(into: storage)
            }
        }

        let collectedLinters = visitor.parallel ?
            linters.parallelCompactMap(transform: collect) :
            linters.compactMap(collect)
        return (collectedLinters, duplicateFileNames)
    }

    private func visit(linters: [CollectedLinter],
                       visitor: LintableFilesVisitor,
                       storage: RuleStorage,
                       duplicateFileNames: Set<String>) -> [SwiftLintFile] {
        var visited = 0
        let visit = { (linter: CollectedLinter) -> SwiftLintFile in
            if !visitor.quiet, let filePath = linter.file.path {
                let outputFilename = self.outputFilename(for: filePath, duplicateFileNames: duplicateFileNames)
                let increment = {
                    visited += 1
                    queuedPrintError("\(visitor.action) '\(outputFilename)' (\(visited)/\(linters.count))")
                }
                if visitor.parallel {
                    indexIncrementerQueue.sync(execute: increment)
                } else {
                    increment()
                }
            }

            autoreleasepool {
                visitor.block(linter)
            }
            return linter.file
        }
        return visitor.parallel ? linters.parallelMap(transform: visit) : linters.map(visit)
    }

    fileprivate func getFiles(with visitor: LintableFilesVisitor) -> Result<[SwiftLintFile], CommandantError<()>> {
        if visitor.useSTDIN {
            let stdinData = FileHandle.standardInput.readDataToEndOfFile()
            if let stdinString = String(data: stdinData, encoding: .utf8) {
                return .success([SwiftLintFile(contents: stdinString)])
            }
            return .failure(.usageError(description: "stdin isn't a UTF8-encoded string"))
        } else if visitor.useScriptInputFiles {
            return scriptInputFiles()
                .map { files in
                    guard visitor.forceExclude else {
                        return files
                    }

                    let scriptInputPaths = files.compactMap { $0.path }
                    let filesToLint = visitor.useExcludingByPrefix
                                      ? filterExcludedPathsByPrefix(in: scriptInputPaths)
                                      : filterExcludedPaths(in: scriptInputPaths)
                    return filesToLint.map(SwiftLintFile.init(pathDeferringReading:))
                }
        }
        if !visitor.quiet {
            let filesInfo: String
            if visitor.paths.isEmpty {
                filesInfo = "in current working directory"
            } else {
                filesInfo = "at paths \(visitor.paths.joined(separator: ", "))"
            }

            queuedPrintError("\(visitor.action) Swift files \(filesInfo)")
        }
        return .success(visitor.paths.flatMap {
            self.lintableFiles(inPath: $0, forceExclude: visitor.forceExclude,
                               excludeByPrefix: visitor.useExcludingByPrefix)
        })
    }

    private static func rootPath(from paths: [String]) -> String? {
        // We don't know the root when more than one path is passed (i.e. not useful if the root of 2 paths is ~)
        return paths.count == 1 ? paths.first?.absolutePathStandardized() : nil
    }

    // MARK: LintOrAnalyze Command

    init(options: LintOrAnalyzeOptions) {
        let cachePath = options.cachePath.isEmpty ? nil : options.cachePath
        self.init(path: options.configurationFile, rootPath: Self.rootPath(from: options.paths),
                  optional: isConfigOptional(), quiet: options.quiet, enableAllRules: options.enableAllRules,
                  cachePath: cachePath)
    }

    func visitLintableFiles(options: LintOrAnalyzeOptions, cache: LinterCache? = nil, storage: RuleStorage,
                            visitorBlock: @escaping (CollectedLinter) -> Void)
        -> Result<[SwiftLintFile], CommandantError<()>> {
            return LintableFilesVisitor.create(options,
                                               cache: cache,
                                               allowZeroLintableFiles: allowZeroLintableFiles,
                                               block: visitorBlock).flatMap({ visitor in
            visitLintableFiles(with: visitor, storage: storage)
        })
    }

    // MARK: AutoCorrect Command

    init(options: AutoCorrectOptions) {
        let cachePath = options.cachePath.isEmpty ? nil : options.cachePath
        self.init(path: options.configurationFile, rootPath: Self.rootPath(from: options.paths),
                  optional: isConfigOptional(), quiet: options.quiet, cachePath: cachePath)
    }

    // MARK: Rules command

    init(options: RulesOptions) {
        self.init(path: options.configurationFile, optional: isConfigOptional())
    }
}

private func isConfigOptional() -> Bool {
    return !CommandLine.arguments.contains("--config")
}

private struct DuplicateCollector {
    var all = Set<String>()
    var duplicates = Set<String>()
}

private extension Collection where Element == Linter {
    var duplicateFileNames: Set<String> {
        let collector = reduce(into: DuplicateCollector()) { result, linter in
            if let filename = linter.file.path?.bridge().lastPathComponent {
                if result.all.contains(filename) {
                    result.duplicates.insert(filename)
                }

                result.all.insert(filename)
            }
        }
        return collector.duplicates
    }
}
