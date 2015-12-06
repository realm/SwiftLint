//
//  Configuration+CommandLine.swift
//  SwiftLint
//
//  Created by JP Simard on 12/5/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation
import SwiftLintFramework

extension Configuration {
    init(commandLinePath: String) {
        self.init(path: commandLinePath, optional: !Process.arguments.contains("--config"))
    }
}
