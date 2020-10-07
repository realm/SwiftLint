import SourceKittenFramework

private let testFunctionNames: Set = [
    "setUp()",
    "setUpWithError()",
    "tearDown()",
    "tearDownWithError()"
]

private let testVariableNames: Set = [
    "allTests"
]

enum XCTestHelpers {
    static func isXCTestMember(kind: SwiftDeclarationKind, name: String) -> Bool {
        if SwiftDeclarationKind.functionKinds.contains(kind) {
            return name.hasPrefix("test") || testFunctionNames.contains(name)
        } else if SwiftDeclarationKind.variableKinds.contains(kind) {
            return testVariableNames.contains(name)
        }

        return false
    }
}
