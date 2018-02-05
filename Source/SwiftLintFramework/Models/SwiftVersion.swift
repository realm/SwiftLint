//
//  SwiftVersion.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 12/29/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

struct SwiftVersion: RawRepresentable {
    typealias RawValue = String

    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }
}

extension SwiftVersion: Comparable {
    // Comparable
    static func < (lhs: SwiftVersion, rhs: SwiftVersion) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

extension SwiftVersion {
    static let three = SwiftVersion(rawValue: "3.0.0")
    static let four = SwiftVersion(rawValue: "4.0.0")
    static let fourDotOne = SwiftVersion(rawValue: "4.1.0")

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

        let file = File(contents: """
            #if swift(>=4.1.0)
                let version = "4.1.0"
            #elseif swift(>=4.0.3)
                let version = "4.0.3"
            #elseif swift(>=4.0.2)
                let version = "4.0.2"
            #elseif swift(>=4.0.1)
                let version = "4.0.1"
            #elseif swift(>=4.0.0)
                let version = "4.0.0"
            #elseif swift(>=3.3.0)
                let version = "3.3.0"
            #elseif swift(>=3.2.3)
                let version = "3.2.3"
            #elseif swift(>=3.2.2)
                let version = "3.2.2"
            #elseif swift(>=3.2.1)
                let version = "3.2.1"
            #elseif swift(>=3.2.0)
                let version = "3.2.0"
            #elseif swift(>=3.1.1)
                let version = "3.1.1"
            #elseif swift(>=3.1.0)
                let version = "3.1.0"
            #elseif swift(>=3.0.2)
                let version = "3.0.2"
            #elseif swift(>=3.0.1)
                let version = "3.0.1"
            #elseif swift(>=3.0.0)
                let version = "3.0.0"
            #endif
            """)
        func isString(token: SyntaxToken) -> Bool {
            return token.type == SyntaxKind.string.rawValue
        }
        if let decl = file.structure.kinds().first(where: { $0.kind == SwiftDeclarationKind.varGlobal.rawValue }),
            let token = file.syntaxMap.tokens(inByteRange: decl.byteRange).first(where: isString ) {
            return .init(rawValue: file.contents.substring(from: token.offset + 1, length: token.length - 2))
        }

        return .three
    }()
}
