//
//  LintCommand.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Commandant
import Curry
import Foundation
import Result
import SourceKittenFramework
import SwiftLintFramework

struct LintCommand: CommandType {
    let verb = "lint"
    let function = "Print lint warnings and errors (default command)"

    func run(options: LintOptions) -> Result<(), CommandantError<()>> {
        var violations = [StyleViolation]()
        var reporter: Reporter.Type!
        var configuration = Configuration(commandLinePath: options.configurationFile)
        configuration.rootPath = options.path.absolutePathStandardized()
        return configuration.visitLintableFiles(options.path, action: "Linting",
            useSTDIN: options.useSTDIN,
            useScriptInputFiles: options.useScriptInputFiles) { linter in
            let currentViolations = linter.styleViolations
            violations += currentViolations
            if reporter == nil { reporter = linter.reporter }
            if reporter.isRealtime {
                let report = reporter.generateReport(currentViolations)
                if !report.isEmpty {
                    queuedPrint(report)
                }
            }
        }.flatMap { files in
            if !reporter.isRealtime {
                queuedPrint(reporter.generateReport(violations))
            }
            let numberOfSeriousViolations = violations.filter({ $0.severity == .Error }).count
            let violationSuffix = (violations.count != 1 ? "s" : "")
            let fileCount = files.count
            let filesSuffix = (fileCount != 1 ? "s." : ".")
            queuedPrintError(
                "Done linting!" +
                " Found \(violations.count) violation\(violationSuffix)," +
                " \(numberOfSeriousViolations) serious" +
                " in \(fileCount) file\(filesSuffix)"
            )
            if (options.strict && !violations.isEmpty) || numberOfSeriousViolations > 0 {
                return .Failure(CommandantError<()>.CommandError())
            }
            return .Success()
        }
    }
}

struct LintOptions: OptionsType {
    let path: String
    let useSTDIN: Bool
    let configurationFile: String
    let strict: Bool
    let useScriptInputFiles: Bool

    // swiftlint:disable line_length
    static func evaluate(mode: CommandMode) -> Result<LintOptions, CommandantError<CommandantError<()>>> {
        let curriedInitializer = curry(self.init)
        return curriedInitializer
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
    // swiftlint:enable line_length
}
