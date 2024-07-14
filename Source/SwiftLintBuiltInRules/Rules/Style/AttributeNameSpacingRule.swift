import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true)
struct AttributeNameSpacingRule: Rule {
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
            Example("private ↓(set) var foo: Bool = false"): Example("private(set) var foo: Bool = false"),
            Example("fileprivate ↓(set) var foo: Bool = false"): Example("fileprivate(set) var foo: Bool = false"),
            Example("internal ↓(set) var foo: Bool = false"): Example("internal(set) var foo: Bool = false"),
            Example("public ↓(set) var foo: Bool = false"): Example("public(set) var foo: Bool = false"),
            Example("public  ↓(set) var foo: Bool = false"): Example("public(set) var foo: Bool = false"),
            Example("@ ↓MainActor"): Example("@MainActor"),
            Example("func test(_ x: @ ↓escaping () -> Int) {}"): Example("func test(_ x: @escaping () -> Int) {}"),
            Example("func test(_ x: @escaping↓() -> Int) {}"): Example("func test(_ x: @escaping () -> Int) {}"),
            Example("@available ↓(*, deprecated)"): Example("@available(*, deprecated)"),
            Example("@MyPropertyWrapper ↓(param: 2) "): Example("@MyPropertyWrapper(param: 2) "),
            Example("nonisolated ↓(unsafe) var _value: X?"): Example("nonisolated(unsafe) var _value: X?"),
            Example("""
            let closure1 = { @MainActor ↓(a, b) in
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

            violations.append(node.name.endPosition)
        }

        override func visitPost(_ node: AttributeSyntax) {
            // Check for trailing trivia after the '@' sign
            // Handles cases like `@ MainActor` / `@ escaping`
            if node.atSign.trailingTrivia.isNotEmpty {
                violations.append(node.atSign.endPosition)
            }

            let hasTrailingTrivia = node.attributeName.trailingTrivia.isNotEmpty

            // Handles cases like @MyPropertyWrapper (param: 2)
            if node.arguments != nil && hasTrailingTrivia {
                violations.append(node.attributeName.endPosition)
            }

            if !hasTrailingTrivia && node.isEscaping {
                // Handles cases where escaping has the wrong spacing: `@escaping()`
                violations.append(node.attributeName.endPosition)
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: DeclModifierSyntax) -> DeclModifierSyntax {
            guard node.detail != nil, node.name.trailingTrivia.isNotEmpty else {
                return super.visit(node)
            }

            correctionPositions.append(node.name.endPosition)

            // Remove leading and trailing whitespace from the name token
            let sanitizedName = node.name.with(\.trailingTrivia, Trivia())
            let newNode = node.with(\.name, sanitizedName)
            return super.visit(newNode)
        }

        override func visit(_ node: AttributeSyntax) -> AttributeSyntax {
            // Check for trailing trivia after the '@' sign and clean it if present
            if node.atSign.trailingTrivia.isNotEmpty {
                let cleanedAtSign = node.atSign.with(\.trailingTrivia, Trivia())
                let newNode = node.with(\.atSign, cleanedAtSign)

                correctionPositions.append(node.atSign.endPosition)
                return super.visit(newNode)
            }

            let hasTrailingTrivia = node.attributeName.trailingTrivia.isNotEmpty
            if node.arguments != nil && hasTrailingTrivia {
                correctionPositions.append(node.attributeName.endPosition)
                let cleanedAttributeName = node.attributeName.with(\.trailingTrivia, Trivia())
                let newNode = node.with(\.attributeName, cleanedAttributeName)
                return super.visit(newNode)
            }

            if !hasTrailingTrivia && node.isEscaping {
                // Handles cases where escaping has the wrong spacing: `@escaping()`
                correctionPositions.append(node.attributeName.endPosition)
                let cleanedAttributeName = node.attributeName.with(\.trailingTrivia, .space)
                let newNode = node.with(\.attributeName, cleanedAttributeName)
                return super.visit(newNode)
            }

            return super.visit(node)
        }
    }
}

private extension AttributeSyntax {
    var isEscaping: Bool {
        attributeNameText == "escaping"
    }
}
