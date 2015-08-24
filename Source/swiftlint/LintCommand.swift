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
            if options.useSTDIN {
                let standardInput = NSFileHandle.fileHandleWithStandardInput()
                let stdinData = standardInput.readDataToEndOfFile()
                let stdinNSString = NSString(data: stdinData, encoding: NSUTF8StringEncoding)
                if let stdinString = stdinNSString as? String {
                    let violations = Linter(file: File(contents: stdinString)).styleViolations
                    print("\n".join(violations.map { $0.description }))
                    return .Success()
                }
                return .Failure(CommandantError<()>.CommandError())
            }

            // Otherwise parse path.
            return self.lint(options.path)
        }
    }

    private func lint(path: String) -> Result<(), CommandantError<()>> {
        let filesToLint = filesToLintAtPath(path)
        if filesToLint.count > 0 {
            if path == "" {
                print("Linting Swift files in current working directory")
            } else {
                print("Linting Swift files at path \(path)")
            }
            var numberOfViolations = 0, numberOfSeriousViolations = 0
            for (index, file) in filesToLint.enumerate() {
                let filename = (file as NSString).lastPathComponent
                print("Linting '\(filename)' (\(index + 1)/\(filesToLint.count))")
                for violation in Linter(file: File(path: file)!).styleViolations {
                    print(violation)
                    numberOfViolations++
                    if violation.severity.isError {
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
            if numberOfSeriousViolations <= 0 {
                return .Success()
            } else {
                // This represents failure of the content (i.e. violations in the files linted)
                // and not failure of the scanning process itself. The current command architecture
                // doesn't discriminate between these types.
                return .Failure(CommandantError<()>.CommandError())
            }
        }
        return .Failure(CommandantError<()>.UsageError(description: "No lintable files found at" +
            " path \(path)"))
    }

    private func filesToLintAtPath(path: String) -> [String] {
        let absolutePath = path.absolutePathRepresentation()
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

    static func create(path: String)(useSTDIN: Bool) -> LintOptions {
        return LintOptions(path: path, useSTDIN: useSTDIN)
    }

    static func evaluate(m: CommandMode) -> Result<LintOptions, CommandantError<()>> {
        return create
            <*> m <| Option(key: "path", defaultValue: "", usage: "the path to the file or" +
                        " directory to lint")
            <*> m <| Option(key: "use-stdin", defaultValue: false, usage: "lint standard input")
    }
}
