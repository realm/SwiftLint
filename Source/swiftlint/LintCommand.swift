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
}

struct LintOptions: OptionsType {
    let path: String
    let useSTDIN: Bool
    let configurationFile: String
    let strict: Bool

    static func create(path: String)(useSTDIN: Bool)(configurationFile: String)(strict: Bool)
        -> LintOptions {
        return LintOptions(path: path, useSTDIN: useSTDIN, configurationFile: configurationFile,
            strict: strict)
    }

    static func evaluate(m: CommandMode) -> Result<LintOptions, CommandantError<()>> {
        return create
            <*> m <| Option(key: "path",
                defaultValue: "",
                usage: "the path to the file or directory to lint")
            <*> m <| Option(key: "use-stdin",
                defaultValue: false,
                usage: "lint standard input")
            <*> m <| Option(key: "config",
                defaultValue: ".swiftlint.yml",
                usage: "the path to SwiftLint's configuration file")
            <*> m <| Option(key: "strict",
                defaultValue: false,
                usage: "fail on warnings")
    }
}
