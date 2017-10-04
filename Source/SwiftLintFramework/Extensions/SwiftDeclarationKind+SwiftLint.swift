//
//  SwiftDeclarationKind+SwiftLint.swift
//  SwiftLint
//
//  Created by JP Simard on 11/17/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import SourceKittenFramework

extension SwiftDeclarationKind {
    internal static let variableKinds: Set<SwiftDeclarationKind> = [
        .varClass,
        .varGlobal,
        .varInstance,
        .varLocal,
        .varParameter,
        .varStatic
    ]

    internal static let functionKinds: Set<SwiftDeclarationKind> = [
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

    internal static let typeKinds: Set<SwiftDeclarationKind> = [
        .`class`,
        .`struct`,
        .`typealias`,
        .`enum`
    ]

}
