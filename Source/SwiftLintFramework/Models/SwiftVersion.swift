//
//  SwiftVersion.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 12/29/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

enum SwiftVersion: String {
    case three = "3"
    case four = "4"

    static let current: SwiftVersion = {
        // Allow forcing the Swift version, useful in cases where SourceKit isn't available
        if let envVersion = ProcessInfo.processInfo.environment["SWIFTLINT_SWIFT_VERSION"] {
            switch envVersion {
            case "4":
                return .four
            default:
                return .three
            }
        }

        let file = File(contents: "#if swift(>=4.0)\nprint(0)\n#endif")
        if !file.structure.dictionary.substructure.isEmpty {
            return .four
        }

        return .three
    }()
}
