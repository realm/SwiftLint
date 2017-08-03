//
//  CommonOptions.swift
//  SwiftLint
//
//  Created by JP Simard on 2/11/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Commandant
import SwiftLintFramework

func pathOption(action: String) -> Option<String> {
    return Option(key: "path",
                  defaultValue: "",
                  usage: "the path to the file or directory to \(action)")
}

let configOption = Option(key: "config",
                          defaultValue: Configuration.fileName,
                          usage: "the path to SwiftLint's configuration file")

let configDefaultsOption = Option<String?>(key: "config-defaults",
                                           defaultValue: nil,
                                           usage: "the path of an external configuration file " +
                                                  "to use as the root of the merge tree")

let configOverridesOption = Option<String?>(key: "config-overrides",
                                            defaultValue: nil,
                                            usage: "the path of an external configuration file " +
                                                   "to append to the end of each branch of the merge tree")

let ignoreNestedConfigsOption = Option(key: "ignore-nested-configs",
                                       defaultValue: false,
                                       usage: "ignores nested configuration files")

let useScriptInputFilesOption = Option(key: "use-script-input-files",
                                       defaultValue: false,
                                       usage: "read SCRIPT_INPUT_FILE* environment variables " +
                                            "as files")

func quietOption(action: String) -> Option<Bool> {
    return Option(key: "quiet",
                  defaultValue: false,
                  usage: "don't print status logs like '\(action.capitalized) <file>' & " +
                    "'Done \(action)'")
}
