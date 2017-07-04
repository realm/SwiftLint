//
//  CommonOptions.swift
//  SwiftLint
//
//  Created by JP Simard on 2/11/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Commandant
import SwiftLintFramework

internal func pathOption(action: String) -> Option<String> {
    return Option(key: "path",
                  defaultValue: "",
                  usage: "the path to the file or directory to \(action)")
}

internal let configOption = Option(key: "config",
                                   defaultValue: Configuration.fileName,
                                   usage: "the path to SwiftLint's configuration file")

internal let useScriptInputFilesOption = Option(key: "use-script-input-files",
                                                defaultValue: false,
                                                usage: "read SCRIPT_INPUT_FILE* environment variables " +
                                            "as files")

internal func quietOption(action: String) -> Option<Bool> {
    return Option(key: "quiet",
                  defaultValue: false,
                  usage: "don't print status logs like '\(action.capitalized) <file>' & " +
                    "'Done \(action)'")
}
