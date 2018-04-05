//
//  Configuration+CommandLine.swift
//  SwiftLint
//
//  Created by JP Simard on 12/5/15.
//  Copyright © 2015 Realm. All rights reserved.
//

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

    func visitLintableFiles(path: String, action: String, useSTDIN: Bool = false,
                            quiet: Bool = false, useScriptInputFiles: Bool, forceExclude: Bool,
                            cache: LinterCache? = nil, parallel: Bool = false,
                            visitorBlock: @escaping (Linter) -> Void) -> Result<[File], CommandantError<()>> {
        return getFiles(path: path, action: action, useSTDIN: useSTDIN, quiet: quiet, forceExclude: forceExclude,
                        useScriptInputFiles: useScriptInputFiles)
        .flatMap { files -> Result<[Configuration: [File]], CommandantError<()>> in
            if files.isEmpty {
                let errorMessage = "No lintable files found at path '\(path)'"
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
    fileprivate func getFiles(path: String, action: String, useSTDIN: Bool, quiet: Bool, forceExclude: Bool,
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
            let message = "\(action) Swift files " + (path.isEmpty ? "in current working directory" : "at path \(path)")
            queuedPrintError(message)
        }
        return .success(lintableFiles(inPath: path, forceExclude: forceExclude))
    }
    // swiftlint:enable function_parameter_count

    // MARK: Lint Command

    init(options: LintOptions) {
        let cachePath = options.cachePath.isEmpty ? nil : options.cachePath
        let optional = !CommandLine.arguments.contains("--config")
        self.init(path: options.configurationFile, rootPath: options.path.absolutePathStandardized(),
                  optional: optional, quiet: options.quiet,
                  enableAllRules: options.enableAllRules, cachePath: cachePath)
    }

    func visitLintableFiles(options: LintOptions, cache: LinterCache? = nil,
                            visitorBlock: @escaping (Linter) -> Void) -> Result<[File], CommandantError<()>> {
        return visitLintableFiles(path: options.path, action: "Linting", useSTDIN: options.useSTDIN,
                                  quiet: options.quiet, useScriptInputFiles: options.useScriptInputFiles,
                                  forceExclude: options.forceExclude, cache: cache, parallel: true,
                                  visitorBlock: visitorBlock)
    }

    // MARK: AutoCorrect Command

    init(options: AutoCorrectOptions) {
        let cachePath = options.cachePath.isEmpty ? nil : options.cachePath
        let optional = !CommandLine.arguments.contains("--config")
        self.init(path: options.configurationFile, rootPath: options.path.absolutePathStandardized(),
                  optional: optional, quiet: options.quiet, cachePath: cachePath)
    }

    // MARK: Rules command

    init(options: RulesOptions) {
        let optional = !CommandLine.arguments.contains("--config")
        self.init(path: options.configurationFile, optional: optional)
    }
}
