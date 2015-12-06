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

private let inputFileKey = "SCRIPT_INPUT_FILE_COUNT"

func scriptInputFiles() -> Result<[String], CommandantError<()>> {
    func getEnvironmentVariable(variable: String) -> Result<String, CommandantError<()>> {
        let environment = NSProcessInfo.processInfo().environment
        if let value = environment[variable] {
            return .Success(value)
        }
        return .Failure(.UsageError(description: "Environment variable not set: \(variable)"))
    }

    let count: Result<Int, CommandantError<()>> = {
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

    func lintableFilesForPath(path: String) -> [File] {
        let pathsForPath = included.isEmpty ? fileManager.filesToLintAtPath(path) : []
        let excludedPaths = excluded.flatMap(fileManager.filesToLintAtPath)
        let includedPaths = included.flatMap(fileManager.filesToLintAtPath)
        let allPaths = pathsForPath.filter(excludedPaths.contains) + includedPaths
        return allPaths.flatMap(File.maybeSwiftFile)
    }
}
