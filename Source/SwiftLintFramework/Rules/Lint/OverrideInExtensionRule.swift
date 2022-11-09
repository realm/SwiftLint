import SwiftSyntax

struct OverrideInExtensionRule: ConfigurationProviderRule, OptInRule, SwiftSyntaxRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "override_in_extension",
        name: "Override in Extension",
        description: "Extensions shouldn't override declarations.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("extension Person {\n  var age: Int { return 42 }\n}\n"),
            Example("extension Person {\n  func celebrateBirthday() {}\n}\n"),
            Example("class Employee: Person {\n  override func celebrateBirthday() {}\n}\n"),
            Example("""
            class Foo: NSObject {}
            extension Foo {
                override var description: String { return "" }
            }
            """),
            Example("""
            struct Foo {
                class Bar: NSObject {}
            }
            extension Foo.Bar {
                override var description: String { return "" }
            }
            """)
        ],
        triggeringExamples: [
            Example("extension Person {\n  override ↓var age: Int { return 42 }\n}\n"),
            Example("extension Person {\n  override ↓func celebrateBirthday() {}\n}\n")
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        let allowedExtensions = ClassNameCollectingVisitor(viewMode: .sourceAccurate)
            .walk(tree: file.syntaxTree, handler: \.classNames)
        return Visitor(allowedExtensions: allowedExtensions)
    }
}

private extension OverrideInExtensionRule {
    final class Visitor: ViolationsSyntaxVisitor {
        private let allowedExtensions: Set<String>

        init(allowedExtensions: Set<String>) {
            self.allowedExtensions = allowedExtensions
            super.init(viewMode: .sourceAccurate)
        }

        override var skippableDeclarations: [DeclSyntaxProtocol.Type] { .allExcept(ExtensionDeclSyntax.self) }

        override func visitPost(_ node: FunctionDeclSyntax) {
            if node.modifiers.containsOverride {
                violations.append(node.funcKeyword.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: VariableDeclSyntax) {
            if node.modifiers.containsOverride {
                violations.append(node.letOrVarKeyword.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
            guard let type = node.extendedType.as(SimpleTypeIdentifierSyntax.self),
                  !allowedExtensions.contains(type.name.text) else {
                return .skipChildren
            }

            return .visitChildren
        }
    }
}

private class ClassNameCollectingVisitor: ViolationsSyntaxVisitor {
    private(set) var classNames: Set<String> = []

    override var skippableDeclarations: [DeclSyntaxProtocol.Type] { .all }

    override func visitPost(_ node: ClassDeclSyntax) {
        classNames.insert(node.identifier.text)
    }
}
