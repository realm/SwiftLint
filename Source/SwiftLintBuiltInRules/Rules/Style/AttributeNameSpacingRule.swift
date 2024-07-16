import SwiftSyntax

@SwiftSyntaxRule
struct AttributeNameSpacingRule: SwiftSyntaxCorrectableRule {
    var configuration = SeverityConfiguration<Self>(.error)

    static let description = RuleDescription(
        identifier: "attribute_name_spacing",
        name: "Attribute Name Spacing",
        description: "There should not be a space between an attribute name and (",
        kind: .style,
        nonTriggeringExamples: [
            Example("private(set) var foo: Bool = false"),
            Example("fileprivate(set) var foo: Bool = false"),
            Example("@MainActor"),
            Example("func funcWithEscapingClosure(_ x: @escaping () -> Int) {}"),
            Example("@available(*, deprecated)"),
            Example("@MyPropertyWrapper(param: 2) "),
            Example("nonisolated(unsafe) var _value: X?"),
            Example("@testable import SwiftLintCore"),
            Example("func func_type_attribute_with_space(x: @convention(c) () -> Int) {}"),
            Example("""
            @propertyWrapper
            struct MyPropertyWrapper {
                var wrappedValue: Int = 1

                init(param: Int) {}
            }
            """),
            Example("""
            let closure2 = { @MainActor
              (a: Int, b: Int) in
            }
            """),
        ],
        triggeringExamples: [
            Example("private ↓(set) var foo: Bool = false"),
            Example("fileprivate ↓(set) var foo: Bool = false"),
            Example("public ↓(set) var foo: Bool = false"),
            Example("  public  ↓(set) var foo: Bool = false"),
            Example("@ ↓MainActor"),
            Example("func funcWithEscapingClosure(_ x: @ ↓escaping () -> Int) {}"),
            Example("func funcWithEscapingClosure(_ x: @escaping↓() -> Int) {}"),
            Example("@available ↓(*, deprecated)"),
            Example("@MyPropertyWrapper ↓(param: 2) "),
            Example("nonisolated ↓(unsafe) var _value: X?"),
            Example("""
            let closure1 = { @MainActor ↓(a, b) in
            }
            """),
        ],
        corrections: [
            Example("private↓ (set) var foo: Bool = false"): Example("private(set) var foo: Bool = false"),
            Example("fileprivate↓ (set) var foo: Bool = false"): Example("fileprivate(set) var foo: Bool = false"),
            Example("internal↓ (set) var foo: Bool = false"): Example("internal(set) var foo: Bool = false"),
            Example("public↓ (set) var foo: Bool = false"): Example("public(set) var foo: Bool = false"),
            Example("public↓  (set) var foo: Bool = false"): Example("public(set) var foo: Bool = false"),
            Example("@↓ MainActor"): Example("@MainActor"),
            Example("func test(_ x: @↓ escaping () -> Int) {}"): Example("func test(_ x: @escaping () -> Int) {}"),
            Example("func test(_ x: @escaping↓() -> Int) {}"): Example("func test(_ x: @escaping () -> Int) {}"),
            Example("@available↓ (*, deprecated)"): Example("@available(*, deprecated)"),
            Example("@MyPropertyWrapper↓ (param: 2) "): Example("@MyPropertyWrapper(param: 2) "),
            Example("nonisolated↓ (unsafe) var _value: X?"): Example("nonisolated(unsafe) var _value: X?"),
            Example("""
            let closure1 = { @MainActor↓ (a, b) in
            }
            """): Example("""
            let closure1 = { @MainActor(a, b) in
            }
            """),
        ]
    )
}

private extension AttributeNameSpacingRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: DeclModifierSyntax) {
            guard node.detail != nil, node.name.trailingTrivia.isNotEmpty else {
                return
            }

            addViolation(
                startPosition: node.name.endPositionBeforeTrailingTrivia,
                endPosition: node.name.endPosition,
                replacement: ""
            )
        }

        override func visitPost(_ node: AttributeSyntax) {
            // Check for trailing trivia after the '@' sign
            // Handles cases like `@ MainActor` / `@ escaping`
            if node.atSign.trailingTrivia.isNotEmpty {
                addViolation(
                    startPosition: node.atSign.endPositionBeforeTrailingTrivia,
                    endPosition: node.atSign.endPosition,
                    replacement: ""
                )
            }

            let hasTrailingTrivia = node.attributeName.trailingTrivia.isNotEmpty

            // Handles cases like @MyPropertyWrapper (param: 2)
            if node.arguments != nil && hasTrailingTrivia {
                addViolation(
                    startPosition: node.attributeName.endPositionBeforeTrailingTrivia,
                    endPosition: node.attributeName.endPosition,
                    replacement: ""
                )
            }

            if !hasTrailingTrivia && node.isEscaping {
                // Handles cases where escaping has the wrong spacing: `@escaping()`
                addViolation(
                    startPosition: node.attributeName.endPositionBeforeTrailingTrivia,
                    endPosition: node.attributeName.endPosition,
                    replacement: " "
                )
            }
        }

        private func addViolation(
            startPosition: AbsolutePosition,
            endPosition: AbsolutePosition,
            replacement: String
        ) {
            violations.append(endPosition)

            let correction = ViolationCorrection(
                start: startPosition,
                end: endPosition,
                replacement: replacement
            )
            violationCorrections.append(correction)
        }
    }
}

private extension AttributeSyntax {
    var isEscaping: Bool {
        attributeNameText == "escaping"
    }
}
