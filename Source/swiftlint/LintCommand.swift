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
                    let file = File(contents: stdinString)
                    let linter = Linter(file: file, configuration: configuration)
                    print(linter.generateReport())
                    return .Success()
                }
                return .Failure(CommandantError<()>.CommandError())
            }

            // Otherwise parse path.
            return lint(options.path, configuration: configuration, strict: options.strict)
        }
    }

    private func lint(path: String,
        configuration: Configuration, strict: Bool) -> Result<(), CommandantError<()>> {
        let filesToLint = (configuration.included.count == 0 ? filesToLintAtPath(path) : [])
            .filter({ !configuration.excluded.flatMap(filesToLintAtPath).contains($0) }) +
            configuration.included.flatMap(filesToLintAtPath)
        if filesToLint.count > 0 {
            if path.isEmpty {
                print("Linting Swift files in current working directory")
            } else {
                print("Linting Swift files at path \(path)")
            }
            var numberOfViolations = 0, numberOfSeriousViolations = 0
            for (index, path) in filesToLint.enumerate() {
                let filename = (path as NSString).lastPathComponent
                print("Linting '\(filename)' (\(index + 1)/\(filesToLint.count))")
                let file = File(path: path)!
                for violation in Linter(file: file, configuration: configuration).styleViolations {
                    fputs("\(violation)\n", stderr)
                    numberOfViolations++
                    if violation.severity == .Error {
                        numberOfSeriousViolations++
                    }
                }
            }
            let violationSuffix = (numberOfViolations != 1 ? "s" : "")
            let filesSuffix = (filesToLint.count != 1 ? "s." : ".")
            print(
                "Done linting!" +
                " Found \(numberOfViolations) violation\(violationSuffix)," +
                " \(numberOfSeriousViolations) serious" +
                " in \(filesToLint.count) file\(filesSuffix)"
            )
            if strict && numberOfViolations > 0 {
                return .Failure(CommandantError<()>.CommandError())
            } else if numberOfSeriousViolations <= 0 {
                return .Success()
            }
            return .Failure(CommandantError<()>.CommandError())
        }
        return .Failure(CommandantError<()>.UsageError(description: "No lintable files found at" +
            " path \(path)"))
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
