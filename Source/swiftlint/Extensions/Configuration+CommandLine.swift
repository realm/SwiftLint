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
    func getEnvironmentVariable(variable: String) -> Result<String, CommandantError<()>> {
        let environment = NSProcessInfo.processInfo().environment
        if let value = environment[variable] {
            return .Success(value)
        }
        return .Failure(.UsageError(description: "Environment variable not set: \(variable)"))
    }

    let count: Result<Int, CommandantError<()>> = {
        let inputFileKey = "SCRIPT_INPUT_FILE_COUNT"
        guard let countString = NSProcessInfo.processInfo().environment[inputFileKey] else {
            return .Failure(.UsageError(description: "\(inputFileKey) variable not set"))
        }
        if let count = Int(countString) {
            return .Success(count)
        }
        return .Failure(.UsageError(description: "\(inputFileKey) did not specify a number"))
    }()

    return count.flatMap { count in
        let inputFiles = (0..<count)
            .map { getEnvironmentVariable("SCRIPT_INPUT_FILE_\($0)") }
            .flatMap { path -> String? in
                switch path {
                case let .Success(path):
                    return path
                case let .Failure(error):
                    queuedPrintError(String(error))
                    return nil
                }
        }
        return Result(inputFiles)
    }
}

extension File {
    private static func maybeSwiftFile(path: String) -> File? {
        if let file = File(path: path) where path.isSwiftFile() {
            return file
        }
        return nil
    }
}

extension Configuration {
    init(commandLinePath: String) {
        self.init(path: commandLinePath, optional: !Process.arguments.contains("--config"))
    }

    func visitLintableFiles(path: String, action: String, useSTDIN: Bool = false,
                            useScriptInputFiles: Bool, visitorBlock: (Linter) -> ()) ->
                            Result<[File], CommandantError<()>> {
        return getFiles(path, action: action, useSTDIN: useSTDIN,
                        useScriptInputFiles: useScriptInputFiles)
            .flatMap { files -> Result<[File], CommandantError<()>> in
                if files.isEmpty {
                    let errorMessage = "No lintable files found at path '\(path)'"
                    return .Failure(CommandantError<()>.UsageError(description: errorMessage))
                }
                return .Success(files)
            }.flatMap { files in
                let fileCount = files.count
                for (index, file) in files.enumerate() {
                    if let path = file.path {
                        let filename = (path as NSString).lastPathComponent
                        queuedPrintError("\(action) '\(filename)' (\(index + 1)/\(fileCount))")
                    }
                    visitorBlock(Linter(file: file, configuration: configForFile(file)))
                }
                return .Success(files)
        }
    }

    private func getFiles(path: String, action: String, useSTDIN: Bool,
                          useScriptInputFiles: Bool) -> Result<[File], CommandantError<()>> {
        if useSTDIN {
            let standardInput = NSFileHandle.fileHandleWithStandardInput()
            let stdinData = standardInput.readDataToEndOfFile()
            let stdinNSString = NSString(data: stdinData, encoding: NSUTF8StringEncoding)
            if let stdinString = stdinNSString as? String {
                return .Success([File(contents: stdinString)])
            }
            return .Failure(.UsageError(description: "stdin isn't a UTF8-encoded string"))
        } else if useScriptInputFiles {
            return scriptInputFiles().map { $0.flatMap(File.maybeSwiftFile) }
        }
        queuedPrintError(
            "\(action) Swift files " +
            (path.isEmpty ? "in current working directory" : "at path \(path)")
        )
        return .Success(lintableFilesForPath(path))
    }
}
