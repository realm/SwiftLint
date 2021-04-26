import SourceKittenFramework

private let testVariableNames: Set = [
    "allTests"
]

private func hasParameters(dictionary: SourceKittenDictionary) -> Bool {
    let nameRange = ByteRange(location: dictionary.nameOffset ?? 0, length: dictionary.nameLength ?? 0)
    for subDictionary in dictionary.substructure {
        if subDictionary.declarationKind == .varParameter,
            let parameterOffset = subDictionary.offset,
            nameRange.contains(parameterOffset) {
            return true
        }
    }

    return false
}

enum XCTestHelpers {
    static func isXCTestMember(kind: SwiftDeclarationKind, name: String,
                               dictionary: SourceKittenDictionary) -> Bool {
        return dictionary.enclosedSwiftAttributes.contains(.override)
            || (kind == .functionMethodInstance && name.hasPrefix("test") && !hasParameters(dictionary: dictionary))
            || ([.varStatic, .varClass].contains(kind) && testVariableNames.contains(name))
    }
}
