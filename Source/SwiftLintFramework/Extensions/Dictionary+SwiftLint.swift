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

    /// Accessibility.
    var accessibility: String? {
        return self["key.accessibility"] as? String
    }
    /// Body length.
    var bodyLength: Int? {
        return (self["key.bodylength"] as? Int64).flatMap({ Int($0) })
    }
    /// Body offset.
    var bodyOffset: Int? {
        return (self["key.bodyoffset"] as? Int64).flatMap({ Int($0) })
    }
    /// Kind.
    var kind: String? {
        return self["key.kind"] as? String
    }
    /// Length.
    var length: Int? {
        return (self["key.length"] as? Int64).flatMap({ Int($0) })
    }
    /// Name.
    var name: String? {
        return self["key.name"] as? String
    }
    /// Name length.
    var nameLength: Int? {
        return (self["key.namelength"] as? Int64).flatMap({ Int($0) })
    }
    /// Name offset.
    var nameOffset: Int? {
        return (self["key.nameoffset"] as? Int64).flatMap({ Int($0) })
    }
    /// Offset.
    var offset: Int? {
        return (self["key.offset"] as? Int64).flatMap({ Int($0) })
    }
    /// Setter accessibility.
    var setterAccessibility: String? {
        return self["key.setter_accessibility"] as? String
    }
    /// Type name.
    var typeName: String? {
        return self["key.typename"] as? String
    }
    /// Column where the token's declaration begins.
    var docColumn: Int? {
        return (self["key.doc.column"] as? Int64).flatMap({ Int($0) })
    }
    /// Line where the token's declaration begins.
    var docLine: Int? {
        return (self["key.doc.line"] as? Int64).flatMap({ Int($0) })
    }
    /// Parsed scope start.
    var docType: Int? {
        return (self["key.doc.type"] as? Int64).flatMap({ Int($0) })
    }
    /// Parsed scope start end.
    var usr: Int? {
        return (self["key.usr"] as? Int64).flatMap({ Int($0) })
    }

    var enclosedSwiftAttributes: [String] {
        let array = self["key.attributes"] as? [SourceKitRepresentable] ?? []
        return array.flatMap { ($0 as? [String: String])?["key.attribute"] }
    }

    var substructure: [[String: SourceKitRepresentable]] {
        let substructure = self["key.substructure"] as? [SourceKitRepresentable] ?? []
        return substructure.flatMap { $0 as? [String: SourceKitRepresentable] }
    }

    var elements: [[String: SourceKitRepresentable]]? {
        let elements = self["key.elements"] as? [SourceKitRepresentable]
        return elements?.flatMap { $0 as? [String: SourceKitRepresentable] }
    }

    var enclosedVarParameters: [[String: SourceKitRepresentable]] {
        return substructure.flatMap { subDict -> [[String: SourceKitRepresentable]] in
            guard let kindString = subDict.kind else {
                return []
            }

            if SwiftDeclarationKind(rawValue: kindString) == .varParameter {
                switch SwiftVersion.current {
                case .two:
                    // with Swift 2.3, a closure parameter is inside another .varParameter and not inside an .argument
                    let parameters = subDict.enclosedVarParameters + [subDict]
                    return parameters.filter {
                        $0.typeName != nil
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
            guard let kindString = subDict.kind else {
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
        return array.flatMap { ($0 as? [String: String])?.name }
    }

    internal func extractCallsToSuper(methodName: String) -> [String] {
        let superCall = "super.\(methodName)"
        return substructure.flatMap { elems in
            guard let type = elems.kind.flatMap({ SwiftExpressionKind(rawValue: $0) }),
                let name = elems.name,
                type == .call && superCall.contains(name)
                else { return nil }
            return name
        }
    }
}
