//
//  SwiftVersion.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 12/29/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

enum SwiftVersion {
    case two
    case three

    static let current: SwiftVersion = {
        // Allow forcing the Swift version, useful in cases where SourceKit isn't available
        if let envVersion = ProcessInfo.processInfo.environment["SWIFTLINT_SWIFT_VERSION"] {
            if envVersion == "2" {
                return .two
            } else {
                return .three
            }
        }
        let file = File(contents: "#sourceLocation()")
        let kinds = file.syntaxMap.tokens.flatMap { SyntaxKind(rawValue: $0.type) }
        if kinds == [.identifier] {
            return .two
        } else if kinds == [.keyword] {
            return .three
        }

        fatalError("Unexpected Swift version")
    }()
}
