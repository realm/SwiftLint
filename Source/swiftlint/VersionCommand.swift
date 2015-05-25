//
//  VersionCommand.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Commandant
import LlamaKit

private let version = "0.1.0"

struct VersionCommand: CommandType {
    let verb = "version"
    let function = "Display the current version of SwiftLint"

    func run(mode: CommandMode) -> Result<(), CommandantError<()>> {
        switch mode {
        case let .Arguments:
            println(version)

        default:
            break
        }
        return success()
    }
}
