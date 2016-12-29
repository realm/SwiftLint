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
                let nestedParameters = subDict.enclosedVarParameters
                // on Swift 2.3, a closure parameter is inside another .varParameter and not inside an .argument
                if nestedParameters.isEmpty {
                    return [subDict]
                } else {
                    return nestedParameters
                }
            } else if SwiftExpressionKind(rawValue: kindString) == .argument {
                return subDict.enclosedVarParameters
            }

            return []
        }
    }

    var inheritedTypes: [String] {
        let array = self["key.inheritedtypes"] as? [SourceKitRepresentable] ?? []
        return array.flatMap { ($0 as? [String: String])?["key.name"] }
    }
}
