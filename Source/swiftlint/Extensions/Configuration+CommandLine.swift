//
//  Configuration+CommandLine.swift
//  SwiftLint
//
//  Created by JP Simard on 12/5/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Commandant
import Foundation
import Result
import SourceKittenFramework
import SwiftLintFramework

private func scriptInputFiles() -> Result<[String], CommandantError<()>> {
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
        let inputFiles = (0..<count).flatMap { fileNumber -> String? in
            switch getEnvironmentVariable("SCRIPT_INPUT_FILE_\(fileNumber)") {
            case let .success(path):
                return path
            case let .failure(error):
                queuedPrintError(String(describing: error))
                return nil
            }
        }
        return Result(inputFiles)
    }
}

extension File {
    fileprivate static func maybeSwiftFile(_ path: String) -> File? {
        if let file = File(path: path), path.bridge().isSwiftFile() {
            return file
        }
        return nil
    }
}

extension Configuration {
    init(commandLinePath: String, rootPath: String? = nil, quiet: Bool = false) {
        self.init(path: commandLinePath, rootPath: rootPath?.absolutePathStandardized(),
                  optional: !CommandLine.arguments.contains("--config"), quiet: quiet)
    }

    func visitLintableFiles(_ path: String, action: String, useSTDIN: Bool = false,
                            quiet: Bool = false, useScriptInputFiles: Bool,
                            visitorBlock: (Linter) -> Void) -> Result<[File], CommandantError<()>> {
        return getFiles(path, action: action, useSTDIN: useSTDIN, quiet: quiet,
                        useScriptInputFiles: useScriptInputFiles)
        .flatMap { files -> Result<[File], CommandantError<()>> in
            if files.isEmpty {
                let errorMessage = "No lintable files found at path '\(path)'"
                return .failure(.usageError(description: errorMessage))
            }
            return .success(files)
        }.flatMap { files in
            let fileCount = files.count
            for (index, file) in files.enumerated() {
                if !quiet, let path = file.path {
                    let filename = path.bridge().lastPathComponent
                    queuedPrintError("\(action) '\(filename)' (\(index + 1)/\(fileCount))")
                }
                visitorBlock(Linter(file: file, configuration: configurationForFile(file)))
            }
            return .success(files)
        }
    }

    fileprivate func getFiles(_ path: String, action: String, useSTDIN: Bool, quiet: Bool,
                              useScriptInputFiles: Bool) -> Result<[File], CommandantError<()>> {
        if useSTDIN {
            let stdinData = FileHandle.standardInput.readDataToEndOfFile()
            if let stdinString = String(data: stdinData, encoding: .utf8) {
                return .success([File(contents: stdinString)])
            }
            return .failure(.usageError(description: "stdin isn't a UTF8-encoded string"))
        } else if useScriptInputFiles {
            return scriptInputFiles().map { $0.flatMap(File.maybeSwiftFile) }
        }
        if !quiet {
            queuedPrintError(
                "\(action) Swift files " +
                    (path.isEmpty ? "in current working directory" : "at path \(path)")
            )
        }
        return .success(lintableFilesForPath(path))
    }
}
