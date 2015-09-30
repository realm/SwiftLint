//
//  VersionCommand.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Commandant
import Result

private let version = "0.2.0"

struct VersionCommand: CommandType {
    let verb = "version"
    let function = "Display the current version of SwiftLint"

    func run(mode: CommandMode) -> Result<(), CommandantError<()>> {
        switch mode {
        case .Arguments:
            print(version)

        default:
            break
        }
        return .Success()
    }
}
