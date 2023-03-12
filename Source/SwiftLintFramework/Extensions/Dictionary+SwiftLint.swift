import SourceKittenFramework

/// A collection of keys and values as parsed out of SourceKit, with many conveniences for accessing SwiftLint-specific
/// values.
public struct SourceKittenDictionary {
    /// The underlying SourceKitten dictionary.
    public let value: [String: SourceKitRepresentable]
    /// The cached substructure for this dictionary. Empty if there is no substructure.
    public let substructure: [SourceKittenDictionary]

    /// The kind of Swift expression represented by this dictionary, if it is an expression.
    public let expressionKind: SwiftExpressionKind?
    /// The kind of Swift declaration represented by this dictionary, if it is a declaration.
    public let declarationKind: SwiftDeclarationKind?
    /// The kind of Swift statement represented by this dictionary, if it is a statement.
    public let statementKind: StatementKind?

    /// The accessibility level for this dictionary, if it is a declaration.
    public let accessibility: AccessControlLevel?

    /// Creates a SourceKitten dictionary given a `Dictionary<String, SourceKitRepresentable>` input.
    ///
    /// - parameter value: The input dictionary/
    init(_ value: [String: SourceKitRepresentable]) {
        self.value = value

        let substructure = value["key.substructure"] as? [SourceKitRepresentable] ?? []
        self.substructure = substructure.compactMap { $0 as? [String: SourceKitRepresentable] }
            .map(Self.init)

        let stringKind = value["key.kind"] as? String
        self.expressionKind = stringKind.flatMap(SwiftExpressionKind.init)
        self.declarationKind = stringKind.flatMap(SwiftDeclarationKind.init)
        self.statementKind = stringKind.flatMap(StatementKind.init)

        self.accessibility = (value["key.accessibility"] as? String).flatMap(AccessControlLevel.init(identifier:))
    }

    /// Body length
    var bodyLength: ByteCount? {
        return (value["key.bodylength"] as? Int64).map(ByteCount.init)
    }

    /// Body offset.
    var bodyOffset: ByteCount? {
        return (value["key.bodyoffset"] as? Int64).map(ByteCount.init)
    }

    /// Body byte range.
    var bodyByteRange: ByteRange? {
        guard let offset = bodyOffset, let length = bodyLength else { return nil }
        return ByteRange(location: offset, length: length)
    }

    /// Kind.
    var kind: String? {
        return value["key.kind"] as? String
    }

    /// Length.
    var length: ByteCount? {
        return (value["key.length"] as? Int64).map(ByteCount.init)
    }
    /// Name.
    var name: String? {
        return value["key.name"] as? String
    }

    /// Name length.
    var nameLength: ByteCount? {
        return (value["key.namelength"] as? Int64).map(ByteCount.init)
    }

    /// Name offset.
    var nameOffset: ByteCount? {
        return (value["key.nameoffset"] as? Int64).map(ByteCount.init)
    }

    /// Byte range of name.
    var nameByteRange: ByteRange? {
        guard let offset = nameOffset, let length = nameLength else { return nil }
        return ByteRange(location: offset, length: length)
    }

    /// Offset.
    var offset: ByteCount? {
        return (value["key.offset"] as? Int64).map(ByteCount.init)
    }

    /// Returns byte range starting from `offset` with `length` bytes
    var byteRange: ByteRange? {
        guard let offset, let length else { return nil }
        return ByteRange(location: offset, length: length)
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
    var docLength: ByteCount? {
        return (value["key.doclength"] as? Int64).flatMap(ByteCount.init)
    }

    /// The attribute for this dictionary, as returned by SourceKit.
    var attribute: String? {
        return value["key.attribute"] as? String
    }

    /// Module name in `@import` expressions.
    var moduleName: String? {
        return value["key.modulename"] as? String
    }

    /// The line number for this declaration.
    var line: Int64? {
        return value["key.line"] as? Int64
    }

    /// The column number for this declaration.
    var column: Int64? {
        return value["key.column"] as? Int64
    }

    /// The `SwiftDeclarationAttributeKind` values associated with this dictionary.
    var enclosedSwiftAttributes: [SwiftDeclarationAttributeKind] {
        return swiftAttributes.compactMap { $0.attribute }
            .compactMap(SwiftDeclarationAttributeKind.init(rawValue:))
    }

    /// The fully preserved SourceKitten dictionaries for all the attributes associated with this dictionary.
    var swiftAttributes: [SourceKittenDictionary] {
        let array = value["key.attributes"] as? [SourceKitRepresentable] ?? []
        return array.compactMap { $0 as? [String: SourceKitRepresentable] }
            .map(Self.init)
    }

    var elements: [SourceKittenDictionary] {
        let elements = value["key.elements"] as? [SourceKitRepresentable] ?? []
        return elements.compactMap { $0 as? [String: SourceKitRepresentable] }
        .map(Self.init)
    }

    var entities: [SourceKittenDictionary] {
        let entities = value["key.entities"] as? [SourceKitRepresentable] ?? []
        return entities.compactMap { $0 as? [String: SourceKitRepresentable] }
            .map(Self.init)
    }

    var enclosedVarParameters: [SourceKittenDictionary] {
        return substructure.flatMap { subDict -> [SourceKittenDictionary] in
            if subDict.declarationKind == .varParameter {
                return [subDict]
            } else if subDict.expressionKind == .argument ||
                subDict.expressionKind == .closure {
                return subDict.enclosedVarParameters
            }

            return []
        }
    }

    var enclosedArguments: [SourceKittenDictionary] {
        return substructure.flatMap { subDict -> [SourceKittenDictionary] in
            guard subDict.expressionKind == .argument else {
                return []
            }

            return [subDict]
        }
    }

    var inheritedTypes: [String] {
        let array = value["key.inheritedtypes"] as? [SourceKitRepresentable] ?? []
        return array.compactMap { ($0 as? [String: String]).flatMap { $0["key.name"] } }
    }
}

extension SourceKittenDictionary {
    /// Traversing all substuctures of the dictionary hierarchically, calling `traverseBlock` on each node.
    /// Traversing using depth first strategy, so deepest substructures will be passed to `traverseBlock` first.
    ///
    /// - parameter traverseBlock: block that will be called for each substructure in the dictionary.
    ///
    /// - returns: The list of substructure dictionaries with updated values from the traverse block.
    func traverseDepthFirst<T>(traverseBlock: (SourceKittenDictionary) -> [T]?) -> [T] {
        var result: [T] = []
        traverseDepthFirst(collectingValuesInto: &result, traverseBlock: traverseBlock)
        return result
    }

    private func traverseDepthFirst<T>(collectingValuesInto array: inout [T],
                                       traverseBlock: (SourceKittenDictionary) -> [T]?) {
        substructure.forEach { subDict in
            subDict.traverseDepthFirst(collectingValuesInto: &array, traverseBlock: traverseBlock)

            if let collectedValues = traverseBlock(subDict) {
                array += collectedValues
            }
        }
    }

    /// Traversing all entities of the dictionary hierarchically, calling `traverseBlock` on each node.
    /// Traversing using depth first strategy, so deepest substructures will be passed to `traverseBlock` first.
    ///
    /// - parameter traverseBlock: block that will be called for each entity in the dictionary.
    ///
    /// - returns: The list of entity dictionaries with updated values from the traverse block.
    func traverseEntitiesDepthFirst<T>(traverseBlock: (SourceKittenDictionary) -> T?) -> [T] {
        var result: [T] = []
        traverseEntitiesDepthFirst(collectingValuesInto: &result, traverseBlock: traverseBlock)
        return result
    }

    private func traverseEntitiesDepthFirst<T>(collectingValuesInto array: inout [T],
                                               traverseBlock: (SourceKittenDictionary) -> T?) {
        entities.forEach { subDict in
            subDict.traverseEntitiesDepthFirst(collectingValuesInto: &array, traverseBlock: traverseBlock)

            if let collectedValue = traverseBlock(subDict) {
                array.append(collectedValue)
            }
        }
    }
}

extension Dictionary where Key == Example {
    /// Returns a dictionary with SwiftLint violation markers (↓) removed from keys.
    ///
    /// - returns: A new `Dictionary`.
    func removingViolationMarkers() -> [Key: Value] {
        return Dictionary(uniqueKeysWithValues: map { key, value in
            return (key.removingViolationMarkers(), value)
        })
    }
}
