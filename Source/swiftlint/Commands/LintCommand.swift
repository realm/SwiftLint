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

private let numberFormatter: NSNumberFormatter = {
    let formatter = NSNumberFormatter()
    formatter.numberStyle = .DecimalStyle
    return formatter
}()

private func saveBenchmark(fileTimes: [(file: String, time: Double)]) {
    let string = fileTimes
        .sort({ $0.0.time < $0.1.time })
        .map({ timeAndFile in
            let time = numberFormatter.stringFromNumber(timeAndFile.time)!
            let file = (timeAndFile.file as NSString).lastPathComponent
            return "\(time): \(file)"
        })
        .joinWithSeparator("\n")
        + "\n"
    let data = string.dataUsingEncoding(NSUTF8StringEncoding)
    data?.writeToFile("benchmark_files.txt", atomically: true)
}

struct LintCommand: CommandType {
    let verb = "lint"
    let function = "Print lint warnings and errors (default command)"

    func run(options: LintOptions) -> Result<(), CommandantError<()>> {
        var fileTimes = [(file: String, time: Double)]()
        var violations = [StyleViolation]()
        var reporter: Reporter.Type!
        var configuration = Configuration(commandLinePath: options.configurationFile)
        configuration.rootPath = options.path.absolutePathStandardized()
        return configuration.visitLintableFiles(options.path, action: "Linting",
            useSTDIN: options.useSTDIN,
            useScriptInputFiles: options.useScriptInputFiles) { linter in
            let start: NSDate! = options.benchmark ? NSDate() : nil
            let currentViolations = linter.styleViolations
            violations += currentViolations
            if reporter == nil { reporter = linter.reporter }
            if options.benchmark {
                fileTimes.append((linter.file.path ?? "<nopath>", -start.timeIntervalSinceNow))
            }
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
            if options.benchmark {
                saveBenchmark(fileTimes)
            }
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
    let benchmark: Bool

    // swiftlint:disable:next line_length
    static func create(path: String) -> (useSTDIN: Bool) -> (configurationFile: String) -> (strict: Bool) -> (useScriptInputFiles: Bool) -> (benchmark: Bool) -> LintOptions {
        // swiftlint:disable:next line_length
        return { useSTDIN in { configurationFile in { strict in { useScriptInputFiles in { benchmark in
            self.init(path: path, useSTDIN: useSTDIN, configurationFile: configurationFile,
                strict: strict, useScriptInputFiles: useScriptInputFiles, benchmark: benchmark)
        }}}}}
    }

    // swiftlint:disable:next line_length
    static func evaluate(mode: CommandMode) -> Result<LintOptions, CommandantError<CommandantError<()>>> {
        return create
            <*> mode <| Option(key: "path",
                defaultValue: "",
                usage: "the path to the file or directory to lint")
            <*> mode <| Option(key: "use-stdin",
                defaultValue: false,
                usage: "lint standard input")
            <*> mode <| Option(key: "config",
                defaultValue: Configuration.fileName,
                usage: "the path to SwiftLint's configuration file")
            <*> mode <| Option(key: "strict",
                defaultValue: false,
                usage: "fail on warnings")
            <*> mode <| Option(key: "use-script-input-files",
                defaultValue: false,
                usage: "read SCRIPT_INPUT_FILE* environment variables as files")
            <*> mode <| Option(key: "benchmark",
                defaultValue: false,
                usage: "save benchmarks to benchmark_files.txt and benchmark_rules.txt")
    }
}
