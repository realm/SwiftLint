//
//  SwiftVersion.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 12/29/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

enum SwiftVersion {
    case three

    static let current: SwiftVersion = {
        // Allow forcing the Swift version, useful in cases where SourceKit isn't available
        if let envVersion = ProcessInfo.processInfo.environment["SWIFTLINT_SWIFT_VERSION"] {
            switch envVersion {
            default:    return .three
            }
        }

        return .three
    }()
}
