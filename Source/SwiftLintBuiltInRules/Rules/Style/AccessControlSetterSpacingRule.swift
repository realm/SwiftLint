import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true)
struct AccessControlSetterSpacingRule: Rule {
    var configuration = SeverityConfiguration<Self>(.error)

    static let description = RuleDescription(
        identifier: "access_control_setter_spacing",
        name: "Access Control Setter Spacing",
        description: "There should be no space between the access control modifier and setter scope",
        kind: .style,
        nonTriggeringExamples: [
            Example("private(set) var foo: Bool = false"),
            Example("fileprivate(set) var foo: Bool = false"),
            Example("internal(set) var foo: Bool = false"),
            Example("public(set) var foo: Bool = false"),
            Example("open(set) var foo: Bool = false"),
            Example("@MainActor"),
            Example("func funcWithEscapingClosure(_ x: @escaping () -> Int) {}"),
            Example("@available(*, deprecated)"),
            Example("@MyPropertyWrapper(param: 2) "),
            Example("nonisolated(unsafe) var _value: X?"),
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
            """)
        ],
        triggeringExamples: [
            Example("private ↓(set) var foo: Bool = false"),
            Example("fileprivate ↓(set) var foo: Bool = false"),
            Example("internal ↓(set) var foo: Bool = false"),
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
            """)
        ],
        corrections: [
            Example("private ↓(set) var foo: Bool = false"): Example("private(set) var foo: Bool = false"),
            Example("fileprivate ↓(set) var foo: Bool = false"): Example("fileprivate(set) var foo: Bool = false"),
            Example("internal ↓(set) var foo: Bool = false"): Example("internal(set) var foo: Bool = false"),
            Example("public ↓(set) var foo: Bool = false"): Example("public(set) var foo: Bool = false"),
        ]
    )
}

// TODO: add rewriter
private extension AccessControlSetterSpacingRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: DeclModifierSyntax) {
            guard node.detail !=  nil, node.name.trailingTrivia.isNotEmpty else {
                return
            }

            violations.append(node.name.endPosition)
        }

        override func visitPost(_ node: AttributeSyntax) {
            // Handles cases like `@ MainActor` / `@ escaping`
            if node.atSign.trailingTrivia.isNotEmpty {
                violations.append(node.atSign.endPosition)
            }

            // Handles cases like @MyPropertyWrapper (param: 2)
            if let arguments = node.arguments?.as(LabeledExprListSyntax.self), arguments.isNotEmpty,  node.attributeName.trailingTrivia.isNotEmpty {
                violations.append(node.attributeName.endPosition)
            } else if node.attributeName.trailingTrivia.isNotEmpty && node.attributeNameText != "escaping" {
                violations.append(node.attributeName.endPosition)
            } else if node.attributeName.trailingTrivia.isEmpty && node.attributeNameText == "escaping" {
                violations.append(node.attributeName.endPosition)
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: DeclModifierSyntax) -> DeclModifierSyntax {
            guard node.asAccessLevelModifier != nil, node.detail?.detail.tokenKind == .identifier("set"),
                  node.name.trailingTrivia.isNotEmpty else {
                return super.visit(node)
            }

            correctionPositions.append(node.name.endPosition)

            // Remove trailing whitespace from the name token
            let cleanedName = node.name.with(\.trailingTrivia, Trivia())
            let newNode = node.with(\.name, cleanedName)
            return super.visit(newNode)
        }
    }
}
