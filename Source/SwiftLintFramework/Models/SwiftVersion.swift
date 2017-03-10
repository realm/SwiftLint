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
    case twoPointThree
    case three

    static let current: SwiftVersion = {
        // Allow forcing the Swift version, useful in cases where SourceKit isn't available
        if let envVersion = ProcessInfo.processInfo.environment["SWIFTLINT_SWIFT_VERSION"] {
            switch envVersion {
            case "2":   return .two
            case "2.3": return .twoPointThree
            default:    return .three
            }
        }
        let file = File(contents: "#sourceLocation()")
        let kinds = file.syntaxMap.tokens.flatMap { SyntaxKind(rawValue: $0.type) }
        if kinds == [.identifier] {
            let docStructureDescription = File(contents: "/// A\nclass A {}").structure.description
            if docStructureDescription.contains("source.decl.attribute.__raw_doc_comment") {
                return .two
            }
            return .twoPointThree
        } else if kinds == [.keyword] {
            return .three
        }

        fatalError("Unexpected Swift version")
    }()
}
