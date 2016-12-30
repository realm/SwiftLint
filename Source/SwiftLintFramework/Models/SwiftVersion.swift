//
//  SwiftVersion.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 12/29/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import SourceKittenFramework

enum SwiftVersion {
    case two
    case three

    static let current: SwiftVersion = {
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
