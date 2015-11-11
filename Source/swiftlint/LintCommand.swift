//
//  LintCommand.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Commandant
import Foundation
import Result
import SourceKittenFramework
import SwiftLintFramework

let fileManager = NSFileManager.defaultManager()

struct LintCommand: CommandType {
    let verb = "lint"
    let function = "Print lint warnings and errors for the Swift files in the current directory " +
                   "(default command)"

    func run(mode: CommandMode) -> Result<(), CommandantError<()>> {
        return LintOptions.evaluate(mode).flatMap { options in
            let configuration = Configuration(path: options.configurationFile,
                optional: !Process.arguments.contains("--config"))
            if options.useSTDIN {
                let standardInput = NSFileHandle.fileHandleWithStandardInput()
                let stdinData = standardInput.readDataToEndOfFile()
                let stdinNSString = NSString(data: stdinData, encoding: NSUTF8StringEncoding)
                if let stdinString = stdinNSString as? String {
                    return lint([File(contents: stdinString)],
                        configuration: configuration,
                        strict: options.strict)
                }
                return .Failure(CommandantError<()>.CommandError())
            } else if options.useScriptInputFiles {
                return scriptInputFiles().flatMap { paths in
                    let files = paths.flatMap(File.init)
                    return lint(files, configuration: configuration, strict: options.strict)
                }
            }

            // Otherwise parse path.
            return lint(options.path, configuration: configuration, strict: options.strict)
        }
    }

    private func lint(path: String, configuration: Configuration, strict: Bool) ->
        Result<(), CommandantError<()>> {
        let filesToLint = (configuration.included.count == 0 ? filesToLintAtPath(path) : [])
            .filter({ !configuration.excluded.flatMap(filesToLintAtPath).contains($0) }) +
            configuration.included.flatMap(filesToLintAtPath)
        if path.isEmpty {
            fputs("Linting Swift files in current working directory\n", stderr)
        } else {
            fputs("Linting Swift files at path \(path)\n", stderr)
        }
        let files = filesToLint.flatMap(File.init)
        if files.count > 0 {
            return lint(files, configuration: configuration, strict: strict)
        }
        return .Failure(CommandantError<()>.UsageError(description: "No lintable files found at" +
            " path \(path)"))
    }

    private func lint(files: [File], configuration: Configuration, strict: Bool) ->
        Result<(), CommandantError<()>> {
        var violations = [StyleViolation]()
        var reporter: Reporter.Type = XcodeReporter.self
        for (index, file) in files.enumerate() {
            if let path = file.path {
                let filename = (path as NSString).lastPathComponent
                fputs("Linting '\(filename)' (\(index + 1)/\(files.count))\n", stderr)
            }
            let linter = Linter(file: file, configuration: configuration)
            let currentViolations = linter.styleViolations
            violations += currentViolations
            reporter = linter.reporter
            if reporter.isRealtime {
                let report = reporter.generateReport(currentViolations)
                if !report.isEmpty {
                    print(report)
                }
            }
        }
        if !reporter.isRealtime {
            print(reporter.generateReport(violations))
        }
        let numberOfSeriousViolations = violations.filter({ $0.severity == .Error }).count
        let violationSuffix = (violations.count != 1 ? "s" : "")
        let filesSuffix = (files.count != 1 ? "s." : ".")
        fputs(
            "Done linting!" +
            " Found \(violations.count) violation\(violationSuffix)," +
            " \(numberOfSeriousViolations) serious" +
            " in \(files.count) file\(filesSuffix)\n",
            stderr
        )
        if strict && violations.count > 0 {
            return .Failure(CommandantError<()>.CommandError())
        } else if numberOfSeriousViolations <= 0 {
            return .Success()
        }
        return .Failure(CommandantError<()>.CommandError())
    }

    private func filesToLintAtPath(path: String) -> [String] {
        let absolutePath = (path.absolutePathRepresentation() as NSString).stringByStandardizingPath
        var isDirectory: ObjCBool = false
        if fileManager.fileExistsAtPath(absolutePath, isDirectory: &isDirectory) {
            if isDirectory {
                return fileManager.allFilesRecursively(directory: absolutePath).filter {
                    $0.isSwiftFile()
                }
            } else if absolutePath.isSwiftFile() {
                return [absolutePath]
            }
        }
        return []
    }

    private func scriptInputFiles() -> Result<[String], CommandantError<()>> {
        func getEnvironmentVariable(variable: String) -> Result<String, CommandantError<()>> {
            let environment = NSProcessInfo.processInfo().environment
            if let value = environment[variable] {
                return .Success(value)
            } else {
                return .Failure(.UsageError(description: "Environment variable not set:" +
                    " \(variable)"))
            }
        }

        let count: Result<Int, CommandantError<()>> = getEnvironmentVariable(
            "SCRIPT_INPUT_FILE_COUNT").flatMap { count in
            if let i = Int(count) {
                return .Success(i)
            } else {
                return .Failure(.UsageError(description: "SCRIPT_INPUT_FILE_COUNT did not specify" +
                    " a number"))
            }
        }

        return count.flatMap { count in
            let variables = (0..<count)
                .map { return getEnvironmentVariable("SCRIPT_INPUT_FILE_\($0)") }
                .flatMap { path -> String? in
                    switch path {
                    case let .Success(path):
                        return path
                    case let .Failure(error):
                        fputs("\(error)\n", stderr)
                        return nil
                    }
            }
            return Result(variables)
        }
    }
}

struct LintOptions: OptionsType {
    let path: String
    let useSTDIN: Bool
    let configurationFile: String
    let strict: Bool
    let useScriptInputFiles: Bool

    static func create(path: String)(useSTDIN: Bool)(configurationFile: String)(strict: Bool)
        (useScriptInputFiles: Bool) -> LintOptions {
        return LintOptions(path: path, useSTDIN: useSTDIN, configurationFile: configurationFile,
            strict: strict, useScriptInputFiles: useScriptInputFiles)
    }

    static func evaluate(mode: CommandMode) -> Result<LintOptions, CommandantError<()>> {
        return create
            <*> mode <| Option(key: "path",
                defaultValue: "",
                usage: "the path to the file or directory to lint")
            <*> mode <| Option(key: "use-stdin",
                defaultValue: false,
                usage: "lint standard input")
            <*> mode <| Option(key: "config",
                defaultValue: ".swiftlint.yml",
                usage: "the path to SwiftLint's configuration file")
            <*> mode <| Option(key: "strict",
                defaultValue: false,
                usage: "fail on warnings")
            <*> mode <| Option(key: "use-script-input-files",
                defaultValue: false,
                usage: "read SCRIPT_INPUT_FILE* environment variables as files")
    }
}
