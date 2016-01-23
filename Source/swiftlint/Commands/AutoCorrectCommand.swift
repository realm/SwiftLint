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
        var configuration = Configuration(commandLinePath: options.configurationFile)
        configuration.rootPath = options.path.absolutePathStandardized()
        return configuration.visitLintableFiles(options.path, action: "Correcting",
            useScriptInputFiles: options.useScriptInputFiles) { linter in
            let corrections = linter.correct()
            if !corrections.isEmpty {
                let correctionLogs = corrections.map({ $0.consoleDescription })
                queuedPrint(correctionLogs.joinWithSeparator("\n"))
            }
        }.flatMap { files in
            queuedPrintError("Done correcting \(files.count) files!")
            return .Success()
        }
    }
}

struct AutoCorrectOptions: OptionsType {
    let path: String
    let configurationFile: String
    let useScriptInputFiles: Bool

    // swiftlint:disable:next line_length
    static func create(path: String) -> (configurationFile: String) -> (useScriptInputFiles: Bool) -> AutoCorrectOptions {
        return { configurationFile in { useScriptInputFiles in
            self.init(path: path, configurationFile: configurationFile,
                      useScriptInputFiles: useScriptInputFiles)
        }}
    }

    // swiftlint:disable:next line_length
    static func evaluate(mode: CommandMode) -> Result<AutoCorrectOptions, CommandantError<CommandantError<()>>> {
        return create
            <*> mode <| Option(key: "path",
                defaultValue: "",
                usage: "the path to the file or directory to correct")
            <*> mode <| Option(key: "config",
                defaultValue: ".swiftlint.yml",
                usage: "the path to SwiftLint's configuration file")
            <*> mode <| Option(key: "use-script-input-files",
                defaultValue: false,
                usage: "read SCRIPT_INPUT_FILE* environment variables as files")
    }
}
