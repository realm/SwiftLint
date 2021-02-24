import Dispatch
import Foundation
import SourceKittenFramework
import SwiftLintFramework

private let indexIncrementerQueue = DispatchQueue(label: "io.realm.swiftlint.indexIncrementer")

private func scriptInputFiles() -> Result<[SwiftLintFile], SwiftLintError> {
    func getEnvironmentVariable(_ variable: String) -> Result<String, SwiftLintError> {
        let environment = ProcessInfo.processInfo.environment
        if let value = environment[variable] {
            return .success(value)
        }
        return .failure(.usageError(description: "Environment variable not set: \(variable)"))
    }

    let count: Result<Int, SwiftLintError> = {
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
        -> Result<[SwiftLintFile], SwiftLintError> {
        return Signposts.record(name: "Configuration.VisitLintableFiles.GetFiles") {
            getFiles(with: visitor)
        }
        .flatMap { files in
            Signposts.record(name: "Configuration.VisitLintableFiles.GroupFiles") {
                groupFiles(files, visitor: visitor)
            }
        }
        .map { file in
            Signposts.record(name: "Configuration.VisitLintableFiles.LintersForFile") {
                linters(for: file, visitor: visitor)
            }
        }
        .map { linters in
            Signposts.record(name: "Configuration.VisitLintableFiles.DuplicateFileNames") {
                (linters, linters.duplicateFileNames)
            }
        }
        .map { linters, duplicateFileNames in
            Signposts.record(name: "Configuration.VisitLintableFiles.Collect") {
                collect(linters: linters, visitor: visitor, storage: storage, duplicateFileNames: duplicateFileNames)
            }
        }
        .map { linters, duplicateFileNames in
            Signposts.record(name: "Configuration.VisitLintableFiles.Visit") {
                visit(linters: linters, visitor: visitor, storage: storage, duplicateFileNames: duplicateFileNames)
            }
        }
    }

    private func groupFiles(_ files: [SwiftLintFile],
                            visitor: LintableFilesVisitor)
        -> Result<[Configuration: [SwiftLintFile]], SwiftLintError> {
        if files.isEmpty && !visitor.allowZeroLintableFiles {
            let errorMessage = "No lintable files found at paths: '\(visitor.paths.joined(separator: ", "))'"
            return .failure(.usageError(description: errorMessage))
        }

        var groupedFiles = [Configuration: [SwiftLintFile]]()
        for file in files {
            let fileConfiguration = configuration(for: file)
            let fileConfigurationRootPath = fileConfiguration.rootDirectory.bridge()

            // Files whose configuration specifies they should be excluded will be skipped
            let shouldSkip = fileConfiguration.excludedPaths.contains { excludedRelativePath in
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
        for component in rootDirectory.bridge().pathComponents where pathComponents.first == component {
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
                Signposts.record(name: "Configuration.Visit", span: .file(linter.file.path ?? "")) {
                    visitor.block(linter)
                }
            }
            return linter.file
        }
        return visitor.parallel ? linters.parallelMap(transform: visit) : linters.map(visit)
    }

    fileprivate func getFiles(with visitor: LintableFilesVisitor) -> Result<[SwiftLintFile], SwiftLintError> {
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
            if visitor.paths.isEmpty || visitor.paths == [""] {
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

    func visitLintableFiles(options: LintOrAnalyzeOptions, cache: LinterCache? = nil, storage: RuleStorage,
                            visitorBlock: @escaping (CollectedLinter) -> Void)
        -> Result<[SwiftLintFile], SwiftLintError> {
            return LintableFilesVisitor.create(options,
                                               cache: cache,
                                               allowZeroLintableFiles: allowZeroLintableFiles,
                                               block: visitorBlock).flatMap({ visitor in
            visitLintableFiles(with: visitor, storage: storage)
        })
    }

    // MARK: LintOrAnalyze Command

    init(options: LintOrAnalyzeOptions) {
        self.init(
            configurationFiles: options.configurationFiles,
            enableAllRules: options.enableAllRules,
            cachePath: options.cachePath
        )
    }
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
