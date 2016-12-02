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
            .VarClass,
            .VarGlobal,
            .VarInstance,
            .VarLocal,
            .VarParameter,
            .VarStatic
        ]
    }

    internal static func functionKinds() -> [SwiftDeclarationKind] {
        return [
            .functionAccessorAddress,
            .functionAccessorDidset,
            .functionAccessorGetter,
            .functionAccessorMutableaddress,
            .functionAccessorSetter,
            .functionAccessorWillset,
            .functionConstructor,
            .functionDestructor,
            .functionFree,
            .functionMethodClass,
            .functionMethodInstance,
            .functionMethodStatic,
            .functionOperator,
            .functionSubscript
        ]
    }

    internal static func typeKinds() -> [SwiftDeclarationKind] {
        return [
            .`class`,
            .`struct`,
            .`typealias`,
            .`enum`
        ]
    }

}
