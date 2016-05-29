//
//  AutoCorrectCommand.swift
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

struct AutoCorrectCommand: CommandType {
    let verb = "autocorrect"
    let function = "Automatically correct warnings and errors"

    func run(options: AutoCorrectOptions) -> Result<(), CommandantError<()>> {
        let configuration = Configuration(commandLinePath: options.configurationFile,
            rootPath: options.path, quiet: options.quiet)
        return configuration.visitLintableFiles(options.path, action: "Correcting",
            quiet: options.quiet, useScriptInputFiles: options.useScriptInputFiles) { linter in
            let corrections = linter.correct()
            if !corrections.isEmpty && !options.quiet {
                let correctionLogs = corrections.map({ $0.consoleDescription })
                queuedPrint(correctionLogs.joinWithSeparator("\n"))
            }
            if options.format {
                let formattedContents = linter.file.format(trimmingTrailingWhitespace: true,
                    useTabs: false,
                    indentWidth: 4)
                _ = try? formattedContents.dataUsingEncoding(NSUTF8StringEncoding)?
                    .writeToFile(linter.file.path!, options: [])
            }
        }.flatMap { files in
            if !options.quiet {
                queuedPrintError("Done correcting \(files.count) files!")
            }
            return .Success()
        }
    }
}

struct AutoCorrectOptions: OptionsType {
    let path: String
    let configurationFile: String
    let useScriptInputFiles: Bool
    let quiet: Bool
    let format: Bool

    // swiftlint:disable line_length
    static func create(path: String) -> (configurationFile: String) -> (useScriptInputFiles: Bool) -> (quiet: Bool) -> (format: Bool) -> AutoCorrectOptions {
        return { configurationFile in { useScriptInputFiles in { quiet in { format in
            self.init(path: path, configurationFile: configurationFile, useScriptInputFiles: useScriptInputFiles, quiet: quiet, format: format)
        }}}}
    }

    static func evaluate(mode: CommandMode) -> Result<AutoCorrectOptions, CommandantError<CommandantError<()>>> {
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
