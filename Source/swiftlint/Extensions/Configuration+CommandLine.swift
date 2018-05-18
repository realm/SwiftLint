import Commandant
import Dispatch
import Foundation
import Result
import SourceKittenFramework
import SwiftLintFramework

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

    func visitLintableFiles(paths: [String], action: String, useSTDIN: Bool = false,
                            quiet: Bool = false, useScriptInputFiles: Bool, forceExclude: Bool,
                            cache: LinterCache? = nil, parallel: Bool = false,
                            visitorBlock: @escaping (Linter) -> Void) -> Result<[File], CommandantError<()>> {
        return getFiles(paths: paths, action: action, useSTDIN: useSTDIN, quiet: quiet, forceExclude: forceExclude,
                        useScriptInputFiles: useScriptInputFiles)
        .flatMap { files -> Result<[Configuration: [File]], CommandantError<()>> in
            if files.isEmpty {
                let errorMessage = "No lintable files found at paths: '\(paths.joined(separator: ", "))'"
                return .failure(.usageError(description: errorMessage))
            }
            return .success(Dictionary(grouping: files, by: configuration(for:)))
        }.flatMap { filesPerConfiguration in
            let queue = DispatchQueue(label: "io.realm.swiftlint.indexIncrementer")
            var index = 0
            let fileCount = filesPerConfiguration.reduce(0) { $0 + $1.value.count }
            let visit = { (file: File, config: Configuration) -> Void in
                if !quiet, let path = file.path {
                    let increment = {
                        index += 1
                        let filename = path.bridge().lastPathComponent
                        queuedPrintError("\(action) '\(filename)' (\(index)/\(fileCount))")
                    }
                    if parallel {
                        queue.sync(execute: increment)
                    } else {
                        increment()
                    }
                }
                autoreleasepool {
                    visitorBlock(Linter(file: file, configuration: config, cache: cache))
                }
            }
            var filesAndConfigurations = [(File, Configuration)]()
            filesAndConfigurations.reserveCapacity(fileCount)
            for (config, files) in filesPerConfiguration {
                let newConfig: Configuration
                if cache != nil {
                    newConfig = config.withPrecomputedCacheDescription()
                } else {
                    newConfig = config
                }
                filesAndConfigurations += files.map { ($0, newConfig) }
            }
            if parallel {
                DispatchQueue.concurrentPerform(iterations: fileCount) { index in
                    let (file, config) = filesAndConfigurations[index]
                    visit(file, config)
                }
            } else {
                filesAndConfigurations.forEach(visit)
            }
            return .success(filesAndConfigurations.compactMap({ $0.0 }))
        }
    }

    // swiftlint:disable function_parameter_count
    fileprivate func getFiles(paths: [String], action: String, useSTDIN: Bool, quiet: Bool, forceExclude: Bool,
                              useScriptInputFiles: Bool) -> Result<[File], CommandantError<()>> {
        if useSTDIN {
            let stdinData = FileHandle.standardInput.readDataToEndOfFile()
            if let stdinString = String(data: stdinData, encoding: .utf8) {
                return .success([File(contents: stdinString)])
            }
            return .failure(.usageError(description: "stdin isn't a UTF8-encoded string"))
        } else if useScriptInputFiles {
            return scriptInputFiles()
        }
        if !quiet {
            let filesInfo = paths.isEmpty ? "in current working directory" : "at paths \(paths.joined(separator: ", "))"
            let message = "\(action) Swift files \(filesInfo)"
            queuedPrintError(message)
        }
        return .success(paths.flatMap {
            self.lintableFiles(inPath: $0, forceExclude: forceExclude)
        })
    }
    // swiftlint:enable function_parameter_count

    private static func rootPath(from paths: [String]) -> String? {
        // We don't know the root when more than one path is passed (i.e. not useful if the root of 2 paths is ~)
        return paths.count == 1 ? paths.first?.absolutePathStandardized() : nil
    }

    // MARK: Lint Command

    init(options: LintOptions) {
        let cachePath = options.cachePath.isEmpty ? nil : options.cachePath
        let optional = !CommandLine.arguments.contains("--config")
        self.init(path: options.configurationFile,
                  rootPath: type(of: self).rootPath(from: options.paths),
                  optional: optional, quiet: options.quiet,
                  enableAllRules: options.enableAllRules,
                  cachePath: cachePath)
    }

    func visitLintableFiles(options: LintOptions, cache: LinterCache? = nil,
                            visitorBlock: @escaping (Linter) -> Void) -> Result<[File], CommandantError<()>> {
        return visitLintableFiles(paths: options.paths, action: "Linting", useSTDIN: options.useSTDIN,
                                  quiet: options.quiet, useScriptInputFiles: options.useScriptInputFiles,
                                  forceExclude: options.forceExclude, cache: cache, parallel: true,
                                  visitorBlock: visitorBlock)
    }

    // MARK: AutoCorrect Command

    init(options: AutoCorrectOptions) {
        let cachePath = options.cachePath.isEmpty ? nil : options.cachePath
        let optional = !CommandLine.arguments.contains("--config")
        self.init(path: options.configurationFile, rootPath: type(of: self).rootPath(from: options.paths),
                  optional: optional, quiet: options.quiet, cachePath: cachePath)
    }

    // MARK: Rules command

    init(options: RulesOptions) {
        let optional = !CommandLine.arguments.contains("--config")
        self.init(path: options.configurationFile, optional: optional)
    }
}
