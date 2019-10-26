import SourceKittenFramework

public struct SourceKittenDictionary {
    public let value: [String: SourceKitRepresentable]
    private let _substructure: [SourceKittenDictionary]
    init(_ value: [String: SourceKitRepresentable]) {
        self.value = value

        let substructure = value["key.substructure"] as? [SourceKitRepresentable] ?? []
        _substructure = substructure.compactMap { $0 as? [String: SourceKitRepresentable] }
            .map(SourceKittenDictionary.init)
    }

    /// Accessibility.
    var accessibility: String? {
        return value["key.accessibility"] as? String
    }

    /// Body length
    var bodyLength: Int? {
        return (value["key.bodylength"] as? Int64).flatMap({ Int($0) })
    }

    /// Body offset.
    var bodyOffset: Int? {
        return (value["key.bodyoffset"] as? Int64).flatMap({ Int($0) })
    }

    /// Kind.
    var kind: String? {
        return value["key.kind"] as? String
    }

    /// Length.
    var length: Int? {
        return (value["key.length"] as? Int64).flatMap({ Int($0) })
    }
    /// Name.
    var name: String? {
        return value["key.name"] as? String
    }

    /// Name length.
    var nameLength: Int? {
        return (value["key.namelength"] as? Int64).flatMap({ Int($0) })
    }

    /// Name offset.
    var nameOffset: Int? {
        return (value["key.nameoffset"] as? Int64).flatMap({ Int($0) })
    }

    /// Offset.
    var offset: Int? {
        return (value["key.offset"] as? Int64).flatMap({ Int($0) })
    }

    /// Setter accessibility.
    var setterAccessibility: String? {
        return value["key.setter_accessibility"] as? String
    }

    /// Type name.
    var typeName: String? {
        return value["key.typename"] as? String
    }

    /// Documentation length.
    var docLength: Int? {
        return (value["key.doclength"] as? Int64).flatMap({ Int($0) })
    }

    var attribute: String? {
        return value["key.attribute"] as? String
    }

    var enclosedSwiftAttributes: [SwiftDeclarationAttributeKind] {
        return swiftAttributes.compactMap { $0.attribute }
            .compactMap(SwiftDeclarationAttributeKind.init(rawValue:))
    }

    var swiftAttributes: [SourceKittenDictionary] {
        let array = value["key.attributes"] as? [SourceKitRepresentable] ?? []
        let dictionaries = array.compactMap { ($0 as? SourceKittenDictionary) }
        return dictionaries
    }

    var substructure: [SourceKittenDictionary] {
        return _substructure
    }

    var elements: [SourceKittenDictionary] {
        let elements = value["key.elements"] as? [SourceKitRepresentable] ?? []
        return elements.compactMap { $0 as? SourceKittenDictionary }
    }

    var entities: [SourceKittenDictionary] {
        let entities = value["key.entities"] as? [SourceKitRepresentable] ?? []
        return entities.compactMap { $0 as? SourceKittenDictionary }
    }

    var enclosedVarParameters: [SourceKittenDictionary] {
        return substructure.flatMap { subDict -> [SourceKittenDictionary] in
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

    var enclosedArguments: [SourceKittenDictionary] {
        return substructure.flatMap { subDict -> [SourceKittenDictionary] in
            guard let kindString = subDict.kind,
                SwiftExpressionKind(rawValue: kindString) == .argument else {
                    return []
            }

            return [subDict]
        }
    }

    var inheritedTypes: [String] {
        let array = value["key.inheritedtypes"] as? [SourceKitRepresentable] ?? []
        return array.compactMap { ($0 as? [String: String]).flatMap { $0["key.name"] } }
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
