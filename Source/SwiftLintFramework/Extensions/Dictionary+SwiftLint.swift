//
//  DynamicInlineRule.swift
//  SwiftLint
//
//  Created by Daniel Duan on 12/08/16.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

extension Dictionary where Key: ExpressibleByStringLiteral {
    var enclosedSwiftAttributes: [String] {
        let array = self["key.attributes"] as? [SourceKitRepresentable] ?? []
        return array.flatMap { ($0 as? [String: String])?["key.attribute"] }
    }

    var substructure: [[String: SourceKitRepresentable]] {
        let substructure = self["key.substructure"] as? [SourceKitRepresentable] ?? []
        return substructure.flatMap { $0 as? [String: SourceKitRepresentable] }
    }

    var enclosedVarParameters: [[String: SourceKitRepresentable]] {
        return substructure.flatMap { subDict -> [[String: SourceKitRepresentable]] in
            guard let kindString = subDict["key.kind"] as? String else {
                return []
            }

            if SwiftDeclarationKind(rawValue: kindString) == .varParameter {
                switch SwiftVersion.current {
                case .two:
                    // with Swift 2.3, a closure parameter is inside another .varParameter and not inside an .argument
                    let parameters = subDict.enclosedVarParameters + [subDict]
                    return parameters.filter {
                        $0["key.typename"] != nil
                    }
                case .three:
                    return [subDict]
                }
            } else if SwiftExpressionKind(rawValue: kindString) == .argument {
                return subDict.enclosedVarParameters
            }

            return []
        }
    }

    var enclosedArguments: [[String: SourceKitRepresentable]] {
        return substructure.flatMap { subDict -> [[String: SourceKitRepresentable]] in
            guard let kindString = subDict["key.kind"] as? String else {
                return []
            }

            switch SwiftVersion.current {
            case .two:
                guard SwiftDeclarationKind(rawValue: kindString) == .varParameter else {
                    return []
                }
            case .three:
                guard SwiftExpressionKind(rawValue: kindString) == .argument else {
                    return []
                }
            }

            return [subDict]
        }
    }

    var inheritedTypes: [String] {
        let array = self["key.inheritedtypes"] as? [SourceKitRepresentable] ?? []
        return array.flatMap { ($0 as? [String: String])?["key.name"] }
    }

    internal func extractCallsToSuper(methodName: String) -> [String] {
        let superCall = "super.\(methodName)"
        return substructure.flatMap { elems in
            guard let type = (elems["key.kind"] as? String).flatMap({ SwiftExpressionKind(rawValue: $0) }),
                let name = elems["key.name"] as? String,
                type == .call && superCall.contains(name)
                else { return nil }
            return name
        }
    }
}
