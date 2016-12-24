//
//  VersionCommand.swift
//  SwiftLint
//
//  Created by JP Simard on 5/16/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation
import Commandant
import Result
import SourceKittenFramework

private let version = Bundle.swiftLintFramework
    .object(forInfoDictionaryKey: "CFBundleShortVersionString")!

struct VersionCommand: CommandProtocol {
    let verb = "version"
    let function = "Display the current version of SwiftLint"

    func run(_ options: NoOptions<CommandantError<()>>) -> Result<(), CommandantError<()>> {
        print(version)
        return .success()
    }
}
