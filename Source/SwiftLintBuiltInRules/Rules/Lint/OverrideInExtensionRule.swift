import SwiftSyntax

struct OverrideInExtensionRule: OptInRule, SwiftSyntaxRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "override_in_extension",
        name: "Override in Extension",
        description: "Extensions shouldn't override declarations",
        kind: .lint,
        nonTriggeringExamples: [
            Example("extension Person {\n  var age: Int { return 42 }\n}"),
            Example("extension Person {\n  func celebrateBirthday() {}\n}"),
            Example("class Employee: Person {\n  override func celebrateBirthday() {}\n}"),
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
            """),
        ],
        triggeringExamples: [
            Example("extension Person {\n  override ↓var age: Int { return 42 }\n}"),
            Example("extension Person {\n  override ↓func celebrateBirthday() {}\n}"),
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor<ConfigurationType> {
        let allowedExtensions = ClassNameCollectingVisitor(
            configuration: configuration,
            file: file
        ).walk(tree: file.syntaxTree, handler: \.classNames)
        return Visitor(
            configuration: configuration,
            file: file,
            allowedExtensions: allowedExtensions
        )
    }
}

private extension OverrideInExtensionRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private let allowedExtensions: Set<String>

        init(configuration: ConfigurationType,
             file: SwiftLintFile,
             allowedExtensions: Set<String>) {
            self.allowedExtensions = allowedExtensions
            super.init(configuration: configuration, file: file)
        }

        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] { .allExcept(ExtensionDeclSyntax.self) }

        override func visitPost(_ node: FunctionDeclSyntax) {
            if node.modifiers.contains(keyword: .override) {
                violations.append(node.funcKeyword.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: VariableDeclSyntax) {
            if node.modifiers.contains(keyword: .override) {
                violations.append(node.bindingSpecifier.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
            guard let type = node.extendedType.as(IdentifierTypeSyntax.self),
                  !allowedExtensions.contains(type.name.text) else {
                return .skipChildren
            }

            return .visitChildren
        }
    }

    final class ClassNameCollectingVisitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private(set) var classNames: Set<String> = []

        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] { .all }

        override func visitPost(_ node: ClassDeclSyntax) {
            classNames.insert(node.name.text)
        }
    }
}
