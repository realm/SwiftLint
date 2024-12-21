import CollectionConcurrencyKit
import Foundation
import SourceKittenFramework

private actor CounterActor {
    private var count = 0

    func next() -> Int {
        count += 1
        return count
    }
}

private func readFilesFromScriptInputFiles() throws -> [SwiftLintFile] {
    let count = try fileCount(from: "SCRIPT_INPUT_FILE_COUNT")
    return (0..<count).compactMap { fileNumber in
        do {
            let environment = ProcessInfo.processInfo.environment
            let variable = "SCRIPT_INPUT_FILE_\(fileNumber)"
            guard let path = environment[variable] else {
                throw SwiftLintError.usageError(description: "Environment variable not set: \(variable)")
            }
            if path.bridge().isSwiftFile() {
                return SwiftLintFile(pathDeferringReading: path)
            }
            return nil
        } catch {
            queuedPrintError(String(describing: error))
            return nil
        }
    }
}

private func readFilesFromScriptInputFileLists() throws -> [SwiftLintFile] {
    let count = try fileCount(from: "SCRIPT_INPUT_FILE_LIST_COUNT")
    return (0..<count).flatMap { fileNumber in
        var filesToLint: [SwiftLintFile] = []
        do {
            let environment = ProcessInfo.processInfo.environment
            let variable = "SCRIPT_INPUT_FILE_LIST_\(fileNumber)"
            guard let path = environment[variable] else {
                throw SwiftLintError.usageError(description: "Environment variable not set: \(variable)")
            }
            if path.bridge().pathExtension == "xcfilelist" {
                guard let fileContents = FileManager.default.contents(atPath: path),
                      let textContents = String(data: fileContents, encoding: .utf8) else {
                    throw SwiftLintError.usageError(description: "Could not read file list at: \(path)")
                }
                textContents.enumerateLines { line, _ in
                    if line.isSwiftFile() {
                        filesToLint.append(SwiftLintFile(pathDeferringReading: line))
                    }
                }
            }
        } catch {
            queuedPrintError(String(describing: error))
        }
        return filesToLint
    }
}

private func fileCount(from envVar: String) throws -> Int {
    guard let countString = ProcessInfo.processInfo.environment[envVar] else {
        throw SwiftLintError.usageError(description: "\(envVar) variable not set")
    }
    guard let count = Int(countString) else {
        throw SwiftLintError.usageError(description: "\(envVar) did not specify a number")
    }
    return count
}

#if os(Linux)
private func autoreleasepool<T>(block: () -> T) -> T { block() }
#endif

extension Configuration {
    func visitLintableFiles(with visitor: LintableFilesVisitor, storage: RuleStorage) async throws -> [SwiftLintFile] {
        let files = try await Signposts.record(name: "Configuration.VisitLintableFiles.GetFiles") {
            try await getFiles(with: visitor)
        }
        let groupedFiles = try Signposts.record(name: "Configuration.VisitLintableFiles.GroupFiles") {
            try groupFiles(files, visitor: visitor)
        }
        let lintersForFile = Signposts.record(name: "Configuration.VisitLintableFiles.LintersForFile") {
            groupedFiles.map { file in
                linters(for: [file.key: file.value], visitor: visitor)
            }
        }
        let duplicateFileNames = Signposts.record(name: "Configuration.VisitLintableFiles.DuplicateFileNames") {
            lintersForFile.map(\.duplicateFileNames)
        }
        let collected = await Signposts.record(name: "Configuration.VisitLintableFiles.Collect") {
            await zip(lintersForFile, duplicateFileNames).asyncMap { linters, duplicateFileNames in
                await collect(linters: linters, visitor: visitor, storage: storage,
                              duplicateFileNames: duplicateFileNames)
            }
        }
        let result = await Signposts.record(name: "Configuration.VisitLintableFiles.Visit") {
            await collected.asyncMap { linters, duplicateFileNames in
                await visit(linters: linters, visitor: visitor, duplicateFileNames: duplicateFileNames)
            }
        }
        return result.flatMap { $0 }
    }

    private func groupFiles(_ files: [SwiftLintFile], visitor: LintableFilesVisitor) throws
        -> [Configuration: [SwiftLintFile]] {
        if files.isEmpty && !visitor.allowZeroLintableFiles {
            throw SwiftLintError.usageError(
                description: "No lintable files found at paths: '\(visitor.options.paths.joined(separator: ", "))'"
            )
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

        return groupedFiles
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
                         duplicateFileNames: Set<String>) async -> ([CollectedLinter], Set<String>) {
        let counter = CounterActor()
        let total = linters.filter(\.isCollecting).count
        let progress = ProgressBar(count: total)
        if visitor.options.progress && total > 0 {
            await progress.initialize()
        }
        let collect = { (linter: Linter) -> CollectedLinter? in
            let skipFile = visitor.shouldSkipFile(atPath: linter.file.path)
            if !visitor.options.quiet && linter.isCollecting {
                if visitor.options.progress {
                    await progress.printNext()
                } else if let filePath = linter.file.path {
                    let outputFilename = self.outputFilename(for: filePath, duplicateFileNames: duplicateFileNames)
                    let collected = await counter.next()
                    if skipFile {
                        Issue.genericWarning(
                            """
                            Skipping '\(outputFilename)' (\(collected)/\(total)) \
                            because its compiler arguments could not be found
                            """
                        ).print()
                    } else {
                        queuedPrintError("Collecting '\(outputFilename)' (\(collected)/\(total))")
                    }
                }
            }

            guard !skipFile else {
                return nil
            }

            return autoreleasepool {
                linter.collect(into: storage)
            }
        }

        let collectedLinters = await visitor.parallel ?
            linters.concurrentCompactMap(collect) :
            linters.asyncCompactMap(collect)
        return (collectedLinters, duplicateFileNames)
    }

    private func visit(linters: [CollectedLinter],
                       visitor: LintableFilesVisitor,
                       duplicateFileNames: Set<String>) async -> [SwiftLintFile] {
        let counter = CounterActor()
        let progress = ProgressBar(count: linters.count)
        if visitor.options.progress {
            await progress.initialize()
        }
        let visit = { (linter: CollectedLinter) -> SwiftLintFile in
            if !visitor.options.quiet {
                if visitor.options.progress {
                    await progress.printNext()
                } else if let filePath = linter.file.path {
                    let outputFilename = self.outputFilename(for: filePath, duplicateFileNames: duplicateFileNames)
                    let visited = await counter.next()
                    queuedPrintError(
                        "\(visitor.options.capitalizedVerb) '\(outputFilename)' (\(visited)/\(linters.count))"
                    )
                }
            }

            await Signposts.record(name: "Configuration.Visit", span: .file(linter.file.path ?? "")) {
                await visitor.block(linter)
            }
            return linter.file
        }
        return await visitor.parallel ?
            linters.concurrentMap(visit) :
            linters.asyncMap(visit)
    }

    fileprivate func getFiles(with visitor: LintableFilesVisitor) async throws -> [SwiftLintFile] {
        let options = visitor.options
        if options.useSTDIN {
            let stdinData = FileHandle.standardInput.readDataToEndOfFile()
            if let stdinString = String(data: stdinData, encoding: .utf8) {
                return [SwiftLintFile(contents: stdinString)]
            }
            throw SwiftLintError.usageError(description: "stdin isn't a UTF8-encoded string")
        }
        if options.useScriptInputFiles || options.useScriptInputFileLists {
            let files = try options.useScriptInputFiles
                ? readFilesFromScriptInputFiles()
                : readFilesFromScriptInputFileLists()
            guard options.forceExclude else {
                return files
            }
            let scriptInputPaths = files.compactMap(\.path)
            return (
                visitor.options.useExcludingByPrefix
                    ? filterExcludedPathsByPrefix(in: scriptInputPaths)
                    : filterExcludedPaths(in: scriptInputPaths)
            ).map(SwiftLintFile.init(pathDeferringReading:))
        }
        if !options.quiet {
            let filesInfo: String
            if options.paths.isEmpty || options.paths == [""] {
                filesInfo = "in current working directory"
            } else {
                filesInfo = "at paths \(options.paths.joined(separator: ", "))"
            }

            queuedPrintError("\(options.capitalizedVerb) Swift files \(filesInfo)")
        }
        return visitor.options.paths.flatMap {
            self.lintableFiles(
                inPath: $0,
                forceExclude: visitor.options.forceExclude,
                excludeByPrefix: visitor.options.useExcludingByPrefix
            )
        }
    }

    func visitLintableFiles(options: LintOrAnalyzeOptions,
                            cache: LinterCache? = nil,
                            storage: RuleStorage,
                            visitorBlock: @escaping (CollectedLinter) async -> Void) async throws -> [SwiftLintFile] {
        let visitor = try LintableFilesVisitor.create(options, cache: cache,
                                                      allowZeroLintableFiles: allowZeroLintableFiles,
                                                      block: visitorBlock)
        return try await visitLintableFiles(with: visitor, storage: storage)
    }

    // MARK: LintOrAnalyze Command

    init(options: LintOrAnalyzeOptions) {
        self.init(
            configurationFiles: options.configurationFiles,
            enableAllRules: options.enableAllRules,
            onlyRule: options.onlyRule,
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
