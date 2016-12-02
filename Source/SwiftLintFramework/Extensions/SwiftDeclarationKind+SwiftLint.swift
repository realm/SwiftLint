//
//  SwiftDeclarationKind+SwiftLint.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-11-17.
//  Copyright © 2015 Realm. All rights reserved.
//

import SourceKittenFramework

extension SwiftDeclarationKind {
    internal static func variableKinds() -> [SwiftDeclarationKind] {
        return [
            .varClass,
            .varGlobal,
            .varInstance,
            .varLocal,
            .varParameter,
            .varStatic
        ]
    }
}
