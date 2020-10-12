import SourceKittenFramework

private let testVariableNames: Set = [
    "allTests"
]

enum XCTestHelpers {
    static func isXCTestMember(kind: SwiftDeclarationKind, name: String,
                               attributes: [SwiftDeclarationAttributeKind]) -> Bool {
        return attributes.contains(.override)
            || (kind == .functionMethodInstance && name.hasPrefix("test"))
            || ([.varStatic, .varClass].contains(kind) && testVariableNames.contains(name))
    }
}
