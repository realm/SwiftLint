import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct NoGroupingExtensionRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "no_grouping_extension",
        name: "No Grouping Extension",
        description: "Extensions shouldn't be used to group code within the same source file",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("protocol Food {}\nextension Food {}"),
            Example("class Apples {}\nextension Oranges {}"),
            Example("class Box<T> {}\nextension Box where T: Vegetable {}"),
        ],
        triggeringExamples: [
            Example("enum Fruit {}\n↓extension Fruit {}"),
            Example("↓extension Tea: Error {}\nstruct Tea {}"),
            Example("class Ham { class Spam {}}\n↓extension Ham.Spam {}"),
            Example("extension External { struct Gotcha {}}\n↓extension External.Gotcha {}"),
        ]
    )

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        Visitor(configuration: configuration, file: file)
            .walk(tree: file.syntaxTree) { visitor in
                visitor.extensionDeclarations.compactMap { decl in
                    guard visitor.typeDeclarations.contains(decl.name) else {
                        return nil
                    }

                    return ReasonedRuleViolation(position: decl.position)
                }
            }
            .sorted()
            .map { makeViolation(file: file, violation: $0) }
    }
}

private extension NoGroupingExtensionRule {
    struct ExtensionDeclaration: Hashable {
        let name: String
        let position: AbsolutePosition
    }

    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private(set) var typeDeclarations = Set<String>()
        private var typeScope: [String] = []
        private(set) var extensionDeclarations = Set<ExtensionDeclaration>()

        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
            [
                ProtocolDeclSyntax.self,
                FunctionDeclSyntax.self,
                VariableDeclSyntax.self,
                InitializerDeclSyntax.self,
                SubscriptDeclSyntax.self,
            ]
        }

        override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
            pushType(named: node.name.text)
            return .visitChildren
        }

        override func visitPost(_: ActorDeclSyntax) {
            typeScope.removeLast()
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            pushType(named: node.name.text)
            return .visitChildren
        }

        override func visitPost(_: ClassDeclSyntax) {
            typeScope.removeLast()
        }

        override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
            pushType(named: node.name.text)
            return .visitChildren
        }

        override func visitPost(_: EnumDeclSyntax) {
            typeScope.removeLast()
        }

        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            pushType(named: node.name.text)
            return .visitChildren
        }

        override func visitPost(_: StructDeclSyntax) {
            typeScope.removeLast()
        }

        override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
            typeScope.append(node.extendedType.trimmedDescription)

            guard node.genericWhereClause == nil else {
                return .skipChildren
            }

            let decl = ExtensionDeclaration(
                name: node.extendedType.trimmedDescription,
                position: node.extensionKeyword.positionAfterSkippingLeadingTrivia
            )
            extensionDeclarations.insert(decl)
            return .visitChildren
        }

        override func visitPost(_: ExtensionDeclSyntax) {
            typeScope.removeLast()
        }

        private func pushType(named name: String) {
            typeScope.append(name)
            typeDeclarations.insert(typeScope.joined(separator: "."))
        }
    }
}
