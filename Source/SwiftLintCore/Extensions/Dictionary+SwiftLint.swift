import SourceKittenFramework

/// A collection of keys and values as parsed out of SourceKit, with many conveniences for accessing SwiftLint-specific
/// values.
public struct SourceKittenDictionary {
    /// The underlying SourceKitten dictionary.
    public let value: [String: any SourceKitRepresentable]
    /// The cached substructure for this dictionary. Empty if there is no substructure.
    public let substructure: [Self]

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
    public init(_ value: [String: any SourceKitRepresentable]) {
        self.value = value

        let substructure = value["key.substructure"] as? [any SourceKitRepresentable] ?? []
        self.substructure = substructure.compactMap { $0 as? [String: any SourceKitRepresentable] }
            .map(Self.init)

        let stringKind = value["key.kind"] as? String
        self.expressionKind = stringKind.flatMap(SwiftExpressionKind.init)
        self.declarationKind = stringKind.flatMap(SwiftDeclarationKind.init)
        self.statementKind = stringKind.flatMap(StatementKind.init)

        self.accessibility = (value["key.accessibility"] as? String).flatMap(AccessControlLevel.init(identifier:))
    }

    /// Body length
    public var bodyLength: ByteCount? {
        (value["key.bodylength"] as? Int64).map(ByteCount.init)
    }

    /// Body offset.
    public var bodyOffset: ByteCount? {
        (value["key.bodyoffset"] as? Int64).map(ByteCount.init)
    }

    /// Body byte range.
    public var bodyByteRange: ByteRange? {
        guard let offset = bodyOffset, let length = bodyLength else { return nil }
        return ByteRange(location: offset, length: length)
    }

    /// Kind.
    public var kind: String? {
        value["key.kind"] as? String
    }

    /// Length.
    public var length: ByteCount? {
        (value["key.length"] as? Int64).map(ByteCount.init)
    }
    /// Name.
    public var name: String? {
        value["key.name"] as? String
    }

    /// Name length.
    public var nameLength: ByteCount? {
        (value["key.namelength"] as? Int64).map(ByteCount.init)
    }

    /// Name offset.
    public var nameOffset: ByteCount? {
        (value["key.nameoffset"] as? Int64).map(ByteCount.init)
    }

    /// Byte range of name.
    public var nameByteRange: ByteRange? {
        guard let offset = nameOffset, let length = nameLength else { return nil }
        return ByteRange(location: offset, length: length)
    }

    /// Offset.
    public var offset: ByteCount? {
        (value["key.offset"] as? Int64).map(ByteCount.init)
    }

    /// Returns byte range starting from `offset` with `length` bytes
    public var byteRange: ByteRange? {
        guard let offset, let length else { return nil }
        return ByteRange(location: offset, length: length)
    }

    /// Setter accessibility.
    public var setterAccessibility: String? {
        value["key.setter_accessibility"] as? String
    }

    /// Type name.
    public var typeName: String? {
        value["key.typename"] as? String
    }

    /// Documentation length.
    public var docLength: ByteCount? {
        (value["key.doclength"] as? Int64).flatMap(ByteCount.init)
    }

    /// The attribute for this dictionary, as returned by SourceKit.
    public var attribute: String? {
        value["key.attribute"] as? String
    }

    /// Module name in `@import` expressions.
    public var moduleName: String? {
        value["key.modulename"] as? String
    }

    /// The line number for this declaration.
    public var line: Int64? {
        value["key.line"] as? Int64
    }

    /// The column number for this declaration.
    public var column: Int64? {
        value["key.column"] as? Int64
    }

    /// The `SwiftDeclarationAttributeKind` values associated with this dictionary.
    public var enclosedSwiftAttributes: [SwiftDeclarationAttributeKind] {
        swiftAttributes.compactMap(\.attribute)
            .compactMap(SwiftDeclarationAttributeKind.init(rawValue:))
    }

    /// The fully preserved SourceKitten dictionaries for all the attributes associated with this dictionary.
    public var swiftAttributes: [Self] {
        let array = value["key.attributes"] as? [any SourceKitRepresentable] ?? []
        return array.compactMap { $0 as? [String: any SourceKitRepresentable] }
            .map(Self.init)
    }

    public var elements: [Self] {
        let elements = value["key.elements"] as? [any SourceKitRepresentable] ?? []
        return elements.compactMap { $0 as? [String: any SourceKitRepresentable] }
        .map(Self.init)
    }

    public var entities: [Self] {
        let entities = value["key.entities"] as? [any SourceKitRepresentable] ?? []
        return entities.compactMap { $0 as? [String: any SourceKitRepresentable] }
            .map(Self.init)
    }

    public var enclosedVarParameters: [Self] {
        substructure.flatMap { subDict -> [Self] in
            if subDict.declarationKind == .varParameter {
                return [subDict]
            }
            if subDict.expressionKind == .argument ||
                subDict.expressionKind == .closure {
                return subDict.enclosedVarParameters
            }

            return []
        }
    }

    public var enclosedArguments: [Self] {
        substructure.flatMap { subDict -> [Self] in
            guard subDict.expressionKind == .argument else {
                return []
            }

            return [subDict]
        }
    }

    public var inheritedTypes: [String] {
        let array = value["key.inheritedtypes"] as? [any SourceKitRepresentable] ?? []
        return array.compactMap { ($0 as? [String: String]).flatMap { $0["key.name"] } }
    }

    public var secondarySymbols: [Self] {
        let array = value["key.secondary_symbols"] as? [any SourceKitRepresentable] ?? []
        return array.compactMap { $0 as? [String: any SourceKitRepresentable] }
            .map(Self.init)
    }
}

extension SourceKittenDictionary {
    /// Block executed for every encountered entity during traversal of a dictionary.
    public typealias TraverseBlock<T> = (_ parent: SourceKittenDictionary, _ entity: SourceKittenDictionary) -> T?

    /// Traversing all substructures of the dictionary hierarchically, calling `traverseBlock` on each node.
    /// Traversing using depth first strategy, so deepest substructures will be passed to `traverseBlock` first.
    ///
    /// - parameter traverseBlock: block that will be called for each substructure in the dictionary.
    ///
    /// - returns: The list of substructure dictionaries with updated values from the traverse block.
    public func traverseDepthFirst<T>(traverseBlock: (SourceKittenDictionary) -> [T]?) -> [T] {
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
    /// - parameter traverseBlock: Block that will be called for each entity and its parent in the dictionary.
    ///
    /// - returns: The list of entity dictionaries with updated values from the traverse block.
    public func traverseEntitiesDepthFirst<T>(traverseBlock: TraverseBlock<T>) -> [T] {
        var result: [T] = []
        traverseEntitiesDepthFirst(collectingValuesInto: &result, traverseBlock: traverseBlock)
        return result
    }

    private func traverseEntitiesDepthFirst<T>(collectingValuesInto array: inout [T], traverseBlock: TraverseBlock<T>) {
        entities.forEach { subDict in
            subDict.traverseEntitiesDepthFirst(collectingValuesInto: &array, traverseBlock: traverseBlock)

            if let collectedValue = traverseBlock(self, subDict) {
                array.append(collectedValue)
            }
        }
    }
}

public extension Dictionary where Key == Example {
    /// Returns a dictionary with SwiftLint violation markers (↓) removed from keys.
    ///
    /// - returns: A new `Dictionary`.
    func removingViolationMarkers() -> [Key: Value] {
        Dictionary(uniqueKeysWithValues: map { key, value in
            (key.removingViolationMarkers(), value)
        })
    }
}
