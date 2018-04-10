//
//  SwiftDeclarationAttributeKind+Swiftlint.swift
//  SwiftLint
//
//  Created by Daniel.Metzing on 04/08/18.
//  Copyright © 2018 Realm. All rights reserved.
//

import SourceKittenFramework

public extension SwiftDeclarationAttributeKind {
    enum ModifierGroup: String, CustomDebugStringConvertible {
        case `override`
        case acl
        case setterACL
        case owned
        case mutators
        case final
        case typeMethods
        case interfaceBuilder
        case objcInteroperability

        var swiftDeclarationAttributeKinds: Set<SwiftDeclarationAttributeKind> {
            switch self {
            case .acl:
                return [.private,
                        .fileprivate,
                        .internal,
                        .public,
                        .open]
            case .setterACL:
                return [.setterPrivate,
                        .setterFilePrivate,
                        .setterInternal,
                        .setterPublic,
                        .setterOpen
                        ]
            case .mutators:
                return [.mutating,
                        .nonmutating]
            case .override:
                return [.override]
            case .owned:
                return [.weak]
            case .final:
                return [.final]
            case .typeMethods:
                return []
            case .objcInteroperability:
                return [.objc,
                        .nonobjc,
                        .objcMembers]
            case .interfaceBuilder:
                return [.ibaction,
                        .iboutlet,
                        .ibdesignable,
                        .ibinspectable]
            }
        }

        static var allValues: Set<SwiftDeclarationAttributeKind.ModifierGroup> {
            return [.acl,
                    .setterACL,
                    .mutators,
                    .override,
                    .owned,
                    .objcInteroperability,
                    .final,
                    .interfaceBuilder,
                    .typeMethods]
        }

        public var debugDescription: String {
            return self.rawValue
        }
    }
}
