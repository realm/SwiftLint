//
//  AutoCorrectCommand.swift
//  SwiftLint
//
//  Created by JP Simard on 12/5/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Commandant
import Result
import SwiftLintFramework

struct AutoCorrectCommand: CommandProtocol {
    let verb = "autocorrect"
    let function = "Automatically correct warnings and errors"

    func run(_ options: AutoCorrectOptions) -> Result<(), CommandantError<()>> {
        return Configuration(options: options).visitLintableFiles(path: options.path, action: "Correcting",
            quiet: options.quiet, useScriptInputFiles: options.useScriptInputFiles) { linter in
            let corrections = linter.correct()
            if !corrections.isEmpty && !options.quiet {
                let correctionLogs = corrections.map({ $0.consoleDescription })
                queuedPrint(correctionLogs.joined(separator:"\n"))
            }
            if options.format {
                let formattedContents = linter.file.format(trimmingTrailingWhitespace: true,
                    useTabs: false,
                    indentWidth: 4)
                _ = try? formattedContents
                    .write(toFile: linter.file.path!, atomically: true, encoding: .utf8)
            }
        }.flatMap { files in
            if !options.quiet {
                queuedPrintError("Done correcting \(files.count) files!")
            }
            return .success()
        }
    }
}

struct AutoCorrectOptions: OptionsProtocol {
    let path: String
    let configurationFile: String
    let useScriptInputFiles: Bool
    let quiet: Bool
    let format: Bool

    // swiftlint:disable line_length
    static func create(_ path: String) -> (_ configurationFile: String) -> (_ useScriptInputFiles: Bool) -> (_ quiet: Bool) -> (_ format: Bool) -> AutoCorrectOptions {
        return { configurationFile in { useScriptInputFiles in { quiet in { format in
            self.init(path: path, configurationFile: configurationFile, useScriptInputFiles: useScriptInputFiles, quiet: quiet, format: format)
        }}}}
    }

    static func evaluate(_ mode: CommandMode) -> Result<AutoCorrectOptions, CommandantError<CommandantError<()>>> {
        // swiftlint:enable line_length
        return create
            <*> mode <| pathOption(action: "correct")
            <*> mode <| configOption
            <*> mode <| useScriptInputFilesOption
            <*> mode <| quietOption(action: "correcting")
            <*> mode <| Option(key: "format",
                               defaultValue: false,
                               usage: "should reformat the Swift files")
    }
}
