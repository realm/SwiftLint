import Commandant
import Dispatch
import Foundation
import Result
import SourceKittenFramework
import SwiftLintFramework

private let indexIncrementerQueue = DispatchQueue(label: "io.realm.swiftlint.indexIncrementer")

private func scriptInputFiles() -> Result<[File], CommandantError<()>> {
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
        let inputFiles = (0..<count).compactMap { fileNumber -> File? in
            switch getEnvironmentVariable("SCRIPT_INPUT_FILE_\(fileNumber)") {
            case let .success(path):
                if path.bridge().isSwiftFile() {
                    return File(pathDeferringReading: path)
                }
                return nil
            case let .failure(error):
                queuedPrintError(String(describing: error))
                return nil
            }
        }
        return Result(inputFiles)
    }
}

#if os(Linux)
private func autoreleasepool(block: () -> Void) { block() }
#endif

extension Configuration {
    func visitLintableFiles(with visitor: LintableFilesVisitor) -> Result<[File], CommandantError<()>> {
        return getFiles(with: visitor)
            .flatMap { groupFiles($0, visitor: visitor) }
            .flatMap { visit(filesPerConfiguration: $0, visitor: visitor) }
    }

    private func groupFiles(_ files: [File],
                            visitor: LintableFilesVisitor) -> Result<[Configuration: [File]], CommandantError<()>> {
        if files.isEmpty {
            let errorMessage = "No lintable files found at paths: '\(visitor.paths.joined(separator: ", "))'"
            return .failure(.usageError(description: errorMessage))
        }
        return .success(Dictionary(grouping: files, by: configuration(for:)))
    }

    private func visit(filesPerConfiguration: [Configuration: [File]],
                       visitor: LintableFilesVisitor) -> Result<[File], CommandantError<()>> {
        var index = 0
        let fileCount = filesPerConfiguration.reduce(0) { $0 + $1.value.count }
        let visit = { (file: File, config: Configuration) -> Void in
            let skipFile = visitor.shouldSkipFile(atPath: file.path)
            if !visitor.quiet, let filename = file.path?.bridge().lastPathComponent {
                let increment = {
                    index += 1
                    if skipFile {
                        queuedPrintError("""
                            Skipping '\(filename)' (\(index)/\(fileCount)) \
                            because its compiler arguments could not be found
                            """)
                    } else {
                        queuedPrintError("\(visitor.action) '\(filename)' (\(index)/\(fileCount))")
                    }
                }
                if visitor.parallel {
                    indexIncrementerQueue.sync(execute: increment)
                } else {
                    increment()
                }
            }

            guard !skipFile else {
                return
            }

            autoreleasepool {
                visitor.block(visitor.linter(forFile: file, configuration: config))
            }
        }
        var filesAndConfigurations = [(File, Configuration)]()
        filesAndConfigurations.reserveCapacity(fileCount)
        for (config, files) in filesPerConfiguration {
            let newConfig: Configuration
            if visitor.cache != nil {
                newConfig = config.withPrecomputedCacheDescription()
            } else {
                newConfig = config
            }
            filesAndConfigurations += files.map { ($0, newConfig) }
        }
        if visitor.parallel {
            DispatchQueue.concurrentPerform(iterations: fileCount) { index in
                let (file, config) = filesAndConfigurations[index]
                visit(file, config)
            }
        } else {
            filesAndConfigurations.forEach(visit)
        }
        return .success(filesAndConfigurations.compactMap({ $0.0 }))
    }

    fileprivate func getFiles(with visitor: LintableFilesVisitor) -> Result<[File], CommandantError<()>> {
        if visitor.useSTDIN {
            let stdinData = FileHandle.standardInput.readDataToEndOfFile()
            if let stdinString = String(data: stdinData, encoding: .utf8) {
                return .success([File(contents: stdinString)])
            }
            return .failure(.usageError(description: "stdin isn't a UTF8-encoded string"))
        } else if visitor.useScriptInputFiles {
            return scriptInputFiles()
                .map { files in
                    guard visitor.forceExclude else {
                        return files
                    }

                    let scriptInputPaths = files.compactMap { $0.path }
                    return filterExcludedPaths(in: scriptInputPaths)
                            .map(File.init(pathDeferringReading:))
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
            self.lintableFiles(inPath: $0, forceExclude: visitor.forceExclude)
        })
    }

    private static func rootPath(from paths: [String]) -> String? {
        // We don't know the root when more than one path is passed (i.e. not useful if the root of 2 paths is ~)
        return paths.count == 1 ? paths.first?.absolutePathStandardized() : nil
    }

    // MARK: LintOrAnalyze Command

    init(options: LintOrAnalyzeOptions) {
        let cachePath = options.cachePath.isEmpty ? nil : options.cachePath
        self.init(path: options.configurationFile, rootPath: type(of: self).rootPath(from: options.paths),
                  optional: isConfigOptional(), quiet: options.quiet, enableAllRules: options.enableAllRules,
                  cachePath: cachePath)
    }

    func visitLintableFiles(options: LintOrAnalyzeOptions, cache: LinterCache? = nil,
                            visitorBlock: @escaping (Linter) -> Void) -> Result<[File], CommandantError<()>> {
        return LintableFilesVisitor.create(options, cache: cache, block: visitorBlock).flatMap(visitLintableFiles)
    }

    // MARK: AutoCorrect Command

    init(options: AutoCorrectOptions) {
        let cachePath = options.cachePath.isEmpty ? nil : options.cachePath
        self.init(path: options.configurationFile, rootPath: type(of: self).rootPath(from: options.paths),
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
