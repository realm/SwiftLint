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
    /// Documentation length.
    var docLength: Int? {
        return (self["key.doclength"] as? Int64).flatMap({ Int($0) })
    }

    var attribute: String? {
        return self["key.attribute"] as? String
    }

    var enclosedSwiftAttributes: [SwiftDeclarationAttributeKind] {
        return swiftAttributes.compactMap { $0.attribute }
                              .compactMap(SwiftDeclarationAttributeKind.init(rawValue:))
    }

    var swiftAttributes: [[String: SourceKitRepresentable]] {
        let array = self["key.attributes"] as? [SourceKitRepresentable] ?? []
        let dictionaries = array.compactMap { ($0 as? [String: SourceKitRepresentable]) }
        return dictionaries
    }

    var substructure: [[String: SourceKitRepresentable]] {
        let substructure = self["key.substructure"] as? [SourceKitRepresentable] ?? []
        return substructure.compactMap { $0 as? [String: SourceKitRepresentable] }
    }

    var elements: [[String: SourceKitRepresentable]] {
        let elements = self["key.elements"] as? [SourceKitRepresentable] ?? []
        return elements.compactMap { $0 as? [String: SourceKitRepresentable] }
    }

    var entities: [[String: SourceKitRepresentable]] {
        let entities = self["key.entities"] as? [SourceKitRepresentable] ?? []
        return entities.compactMap { $0 as? [String: SourceKitRepresentable] }
    }

    var enclosedVarParameters: [[String: SourceKitRepresentable]] {
        return substructure.flatMap { subDict -> [[String: SourceKitRepresentable]] in
            guard let kindString = subDict.kind else {
                return []
            }

            if SwiftDeclarationKind(rawValue: kindString) == .varParameter {
                return [subDict]
            } else if SwiftExpressionKind(rawValue: kindString) == .argument ||
                SwiftExpressionKind(rawValue: kindString) == .closure {
                return subDict.enclosedVarParameters
            }

            return []
        }
    }

    var enclosedArguments: [[String: SourceKitRepresentable]] {
        return substructure.flatMap { subDict -> [[String: SourceKitRepresentable]] in
            guard let kindString = subDict.kind,
                SwiftExpressionKind(rawValue: kindString) == .argument else {
                    return []
            }

            return [subDict]
        }
    }

    var inheritedTypes: [String] {
        let array = self["key.inheritedtypes"] as? [SourceKitRepresentable] ?? []
        return array.compactMap { ($0 as? [String: String])?.name }
    }

    internal func extractCallsToSuper(methodName: String) -> [String] {
        guard let methodNameWithoutArguments = methodName.split(separator: "(").first else {
            return []
        }
        let superCall = "super.\(methodNameWithoutArguments)"
        return substructure.flatMap { elems -> [String] in
            guard let type = elems.kind.flatMap(SwiftExpressionKind.init),
                let name = elems.name,
                type == .call && superCall == name else {
                    return elems.extractCallsToSuper(methodName: methodName)
            }
            return [name]
        }
    }
}

extension Dictionary where Key == String {
    /// Returns a dictionary with SwiftLint violation markers (↓) removed from keys.
    func removingViolationMarkers() -> [Key: Value] {
        return Dictionary(uniqueKeysWithValues: map { ($0.replacingOccurrences(of: "↓", with: ""), $1) })
    }
}
