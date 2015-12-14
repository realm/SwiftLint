//
//  VersionCommand.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Foundation
import Commandant
import Result

private let version = NSBundle(identifier: "io.realm.SwiftLintFramework")!
    .objectForInfoDictionaryKey("CFBundleShortVersionString")!

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
