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

private let version = Bundle(identifier: "io.realm.SwiftLintFramework")!
    .object(forInfoDictionaryKey: "CFBundleShortVersionString")!

struct VersionCommand: CommandProtocol {
    let verb = "version"
    let function = "Display the current version of SwiftLint"

    func run(_ options: NoOptions<CommandantError<()>>) -> Result<(), CommandantError<()>> {
        print(version)
        return .success()
    }
}
