import SwiftSyntax

enum XCTestHelpers {
    private static let testVariableNames: Set = [
        "allTests"
    ]

    static func isXCTestFunction(_ function: FunctionDeclSyntax) -> Bool {
        guard !function.modifiers.containsOverride else {
            return true
        }

        return !function.modifiers.containsStaticOrClass &&
            function.identifier.text.hasPrefix("test") &&
            function.signature.input.parameterList.isEmpty
    }

    static func isXCTestVariable(_ variable: VariableDeclSyntax) -> Bool {
        guard !variable.modifiers.containsOverride else {
            return true
        }

        return
            variable.modifiers.containsStaticOrClass &&
            variable.bindings
                .compactMap { $0.pattern.as(IdentifierPatternSyntax.self)?.identifier.text }
                .allSatisfy(testVariableNames.contains)
    }
}
