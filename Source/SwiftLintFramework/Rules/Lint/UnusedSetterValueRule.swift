import SwiftSyntax

public struct UnusedSetterValueRule: ConfigurationProviderRule, SwiftSyntaxRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "unused_setter_value",
        name: "Unused Setter Value",
        description: "Setter value is not used.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
            var aValue: String {
                get {
                    return Persister.shared.aValue
                }
                set {
                    Persister.shared.aValue = newValue
                }
            }
            """),
            Example("""
            var aValue: String {
                set {
                    Persister.shared.aValue = newValue
                }
                get {
                    return Persister.shared.aValue
                }
            }
            """),
            Example("""
            var aValue: String {
                get {
                    return Persister.shared.aValue
                }
                set(value) {
                    Persister.shared.aValue = value
                }
            }
            """),
            Example("""
            override var aValue: String {
             get {
                 return Persister.shared.aValue
             }
             set { }
            }
            """),
            Example("""
            protocol Foo {
                var bar: Bool { get set }
            """, excludeFromDocumentation: true)
        ],
        triggeringExamples: [
            Example("""
            var aValue: String {
                get {
                    return Persister.shared.aValue
                }
                ↓set {
                    Persister.shared.aValue = aValue
                }
            }
            """),
            Example("""
            var aValue: String {
                ↓set {
                    Persister.shared.aValue = aValue
                }
                get {
                    return Persister.shared.aValue
                }
            }
            """),
            Example("""
            var aValue: String {
                get {
                    return Persister.shared.aValue
                }
                ↓set {
                    Persister.shared.aValue = aValue
                }
            }
            """),
            Example("""
            var aValue: String {
                get {
                    let newValue = Persister.shared.aValue
                    return newValue
                }
                ↓set {
                    Persister.shared.aValue = aValue
                }
            }
            """),
            Example("""
            var aValue: String {
                get {
                    return Persister.shared.aValue
                }
                ↓set(value) {
                    Persister.shared.aValue = aValue
                }
            }
            """),
            Example("""
            override var aValue: String {
                get {
                    return Persister.shared.aValue
                }
                ↓set {
                    Persister.shared.aValue = aValue
                }
            }
            """)
        ]
    )

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor? {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension UnusedSetterValueRule {
    final class Visitor: SyntaxVisitor, ViolationsSyntaxVisitor {
        private(set) var violationPositions: [AbsolutePosition] = []
        private var isInOverridenDecl = false

        override func visitPost(_ node: AccessorDeclSyntax) {
            guard node.accessorKind.tokenKind == .contextualKeyword("set") else {
                return
            }

            let variableName = node.parameter?.name.withoutTrivia().text ?? "newValue"
            let visitor = NewValueUsageVisitor(variableName: variableName)
            if !visitor.walk(tree: node, handler: \.isVariableUsed) {
                if isInOverridenDecl, let body = node.body, body.statements.isEmpty {
                    return
                }

                violationPositions.append(node.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
            isInOverridenDecl = node.modifiers.containsOverride
            return .visitChildren
        }

        override func visit(_ node: SubscriptDeclSyntax) -> SyntaxVisitorContinueKind {
            isInOverridenDecl = node.modifiers.containsOverride
            return .visitChildren
        }

        override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }
    }

    final class NewValueUsageVisitor: SyntaxVisitor {
        let variableName: String
        private(set) var isVariableUsed = false

        init(variableName: String) {
            self.variableName = variableName
            super.init(viewMode: .sourceAccurate)
        }

        override func visitPost(_ node: IdentifierExprSyntax) {
            if node.identifier.withoutTrivia().text == variableName {
                isVariableUsed = true
            }
        }
    }
}

private extension ModifierListSyntax? {
    var containsOverride: Bool {
        self?.contains { elem in
            elem.name.tokenKind == .contextualKeyword("override")
        } ?? false
    }
}
