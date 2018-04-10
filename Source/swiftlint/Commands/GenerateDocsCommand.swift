//
//  RulesDocsCommand.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 01/01/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Commandant
import Result
import SwiftLintFramework

struct GenerateDocsCommand: CommandProtocol {
    let verb = "generate-docs"
    let function = "Generates markdown documentation for all rules"

    func run(_ options: GenerateDocsOptions) -> Result<(), CommandantError<()>> {
        let text = masterRuleList.generateDocumentation()

        if let path = options.path {
            do {
                try text.write(toFile: path, atomically: true, encoding: .utf8)
            } catch {
                return .failure(.usageError(description: error.localizedDescription))
            }
        } else {
            queuedPrint(text)
        }

        return .success(())
    }
}

struct GenerateDocsOptions: OptionsProtocol {
    let path: String?

    static func create(_ path: String?) -> GenerateDocsOptions {
        return self.init(path: path)
    }

    static func evaluate(_ mode: CommandMode) -> Result<GenerateDocsOptions, CommandantError<CommandantError<()>>> {
        return create
            <*> mode <| Option(key: "path", defaultValue: nil,
                               usage: "the path where the documentation should be saved. " +
                                      "If not present, it'll be printed to the output.")
    }
}
