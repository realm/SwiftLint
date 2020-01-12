import Foundation
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
            .map(SourceKittenDictionary.init)

        let stringKind = value["key.kind"] as? String
        self.expressionKind = stringKind.flatMap(SwiftExpressionKind.init)
        self.declarationKind = stringKind.flatMap(SwiftDeclarationKind.init)
        self.statementKind = stringKind.flatMap(StatementKind.init)

        self.accessibility = (value["key.accessibility"] as? String).flatMap(AccessControlLevel.init(identifier:))
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

    /// Returns byte range starting from `offset` with `length` bytes
    var byteRange: NSRange? {
        guard let offset = offset, let length = length else { return nil }
        return NSRange(location: offset, length: length)
    }

    /// Setter accessibility.
    var setterAccessibility: String? {
        return value["key.setter_accessibility"] as? String
    }

    /// Type name.
    var typeName: String? {
        return value["key.typename"] as? String
    }

    /// Documentation offset.
    var docOffset: Int? {
        return (value["key.docoffset"] as? Int64).flatMap({ Int($0) })
    }

    /// Documentation length.
    var docLength: Int? {
        return (value["key.doclength"] as? Int64).flatMap({ Int($0) })
    }

    /// The attribute for this dictionary, as returned by SourceKit.
    var attribute: String? {
        return value["key.attribute"] as? String
    }

    /// The `SwiftDeclarationAttributeKind` values associated with this dictionary.
    var enclosedSwiftAttributes: [SwiftDeclarationAttributeKind] {
        return swiftAttributes.compactMap { $0.attribute }
            .compactMap(SwiftDeclarationAttributeKind.init(rawValue:))
    }

    /// The fully preserved SourceKitten dictionaries for all the attributes associated with this dictionary.
    var swiftAttributes: [SourceKittenDictionary] {
        let array = value["key.attributes"] as? [SourceKitRepresentable] ?? []
        let dictionaries = array.compactMap { $0 as? [String: SourceKitRepresentable] }
            .map(SourceKittenDictionary.init)
        return dictionaries
    }

    var elements: [SourceKittenDictionary] {
        let elements = value["key.elements"] as? [SourceKitRepresentable] ?? []
        return elements.compactMap { $0 as? [String: SourceKitRepresentable] }
        .map(SourceKittenDictionary.init)
    }

    var entities: [SourceKittenDictionary] {
        let entities = value["key.entities"] as? [SourceKitRepresentable] ?? []
        return entities.compactMap { $0 as? [String: SourceKitRepresentable] }
            .map(SourceKittenDictionary.init)
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

    internal func extractCallsToSuper(methodName: String) -> [String] {
        guard let methodNameWithoutArguments = methodName.split(separator: "(").first else {
            return []
        }
        let superCall = "super.\(methodNameWithoutArguments)"
        return substructure.flatMap { elems -> [String] in
            guard let type = elems.expressionKind,
                let name = elems.name,
                type == .call && superCall == name else {
                    return elems.extractCallsToSuper(methodName: methodName)
            }
            return [name]
        }
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

    /// Traversing all substuctures of the dictionary hierarchically, calling `traverseBlock` on each node.
    /// Traversing using depth first strategy, so deepest substructures will be passed to `traverseBlock` first.
    ///
    /// - parameter traverseBlock: block that will be called for each substructure and its parent.
    ///
    /// - returns: The list of substructure dictionaries with updated values from the traverse block.
    func traverseWithParentDepthFirst<T>(traverseBlock: (SourceKittenDictionary, SourceKittenDictionary) -> [T]?)
        -> [T] {
        var result: [T] = []
        traverseWithParentDepthFirst(collectingValuesInto: &result, traverseBlock: traverseBlock)
        return result
    }

    private func traverseWithParentDepthFirst<T>(
        collectingValuesInto array: inout [T],
        traverseBlock: (SourceKittenDictionary, SourceKittenDictionary) -> [T]?) {
        substructure.forEach { subDict in
            subDict.traverseWithParentDepthFirst(collectingValuesInto: &array, traverseBlock: traverseBlock)

            if let collectedValues = traverseBlock(self, subDict) {
                array += collectedValues
            }
        }
    }

    /// Traversing all substuctures of the dictionary hierarchically, calling `traverseBlock` on each node.
    /// Traversing using breadth first strategy, so deepest substructures will be passed to `traverseBlock` last.
    ///
    /// - parameter traverseBlock: block that will be called for each substructure in the dictionary.
    ///
    /// - returns: The list of substructure dictionaries with updated values from the traverse block.
    func traverseBreadthFirst<T>(traverseBlock: (SourceKittenDictionary) -> [T]?) -> [T] {
        var result: [T] = []
        traverseBreadthFirst(collectingValuesInto: &result, traverseBlock: traverseBlock)
        return result
    }

    private func traverseBreadthFirst<T>(collectingValuesInto array: inout [T],
                                         traverseBlock: (SourceKittenDictionary) -> [T]?) {
        substructure.forEach { subDict in
            if let collectedValues = traverseBlock(subDict) {
                array += collectedValues
            }
            subDict.traverseDepthFirst(collectingValuesInto: &array, traverseBlock: traverseBlock)
        }
    }
}

extension Dictionary where Key == String {
    /// Returns a dictionary with SwiftLint violation markers (↓) removed from keys.
    ///
    /// - returns: A new `Dictionary`.
    func removingViolationMarkers() -> [Key: Value] {
        return Dictionary(uniqueKeysWithValues: map { ($0.replacingOccurrences(of: "↓", with: ""), $1) })
    }
}
