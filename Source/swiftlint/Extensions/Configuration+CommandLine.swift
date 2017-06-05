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
        let inputFiles = (0..<count).flatMap { fileNumber -> File? in
            switch getEnvironmentVariable("SCRIPT_INPUT_FILE_\(fileNumber)") {
            case let .success(path):
                if let file = File(path: path), path.bridge().isSwiftFile() {
                    return file
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
                            quiet: Bool = false, useScriptInputFiles: Bool,
                            cache: LinterCache? = nil, parallel: Bool = false,
                            visitorBlock: @escaping (Linter) -> Void) -> Result<[File], CommandantError<()>> {
        return getFiles(path: path, action: action, useSTDIN: useSTDIN, quiet: quiet,
                        useScriptInputFiles: useScriptInputFiles)
        .flatMap { files -> Result<[File], CommandantError<()>> in
            if files.isEmpty {
                let errorMessage = "No lintable files found at path '\(path)'"
                return .failure(.usageError(description: errorMessage))
            }
            return .success(files)
        }.flatMap { files in
            let queue = DispatchQueue(label: "io.realm.swiftlint.indexIncrementer")
            var index = 0
            let fileCount = files.count
            let visit = { (file: File) -> Void in
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
                    visitorBlock(Linter(file: file, configuration: self.configuration(for: file), cache: cache))
                }
            }
            if parallel {
                DispatchQueue.concurrentPerform(iterations: files.count) { index in
                    visit(files[index])
                }
            } else {
                files.forEach(visit)
            }
            return .success(files)
        }
    }

    fileprivate func getFiles(path: String, action: String, useSTDIN: Bool, quiet: Bool,
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
        return .success(lintableFiles(inPath: path))
    }

    // MARK: Lint Command

    init(options: LintOptions) {
        let cachePath = options.cachePath.isEmpty ? nil : options.cachePath
        self.init(commandLinePath: options.configurationFile, rootPath: options.path, quiet: options.quiet,
                  enableAllRules: options.enableAllRules, cachePath: cachePath)
    }

    func visitLintableFiles(options: LintOptions, cache: LinterCache? = nil,
                            visitorBlock: @escaping (Linter) -> Void) -> Result<[File], CommandantError<()>> {
        return visitLintableFiles(path: options.path, action: "Linting", useSTDIN: options.useSTDIN,
                                  quiet: options.quiet, useScriptInputFiles: options.useScriptInputFiles,
                                  cache: cache, parallel: true, visitorBlock: visitorBlock)
    }

    // MARK: AutoCorrect Command

    init(options: AutoCorrectOptions) {
        let cachePath = options.cachePath.isEmpty ? nil : options.cachePath
        self.init(commandLinePath: options.configurationFile, rootPath: options.path,
                  quiet: options.quiet, cachePath: cachePath)
    }
}
