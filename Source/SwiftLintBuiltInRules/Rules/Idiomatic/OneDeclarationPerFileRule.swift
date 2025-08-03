import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct OneDeclarationPerFileRule: Rule {
    var configuration = OneDeclarationPerFileConfiguration()
    static let description = RuleDescription(
        identifier: "one_declaration_per_file",
        name: "One Declaration per File",
        description: "Only a single declaration is allowed in a file",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("""
                    actor Foo {}
                    """),
            Example("""
                    class Foo {}
                    extension Foo {}
                    """),
            Example("""
                    struct S {
                        struct N {}
                    }
                    """),
            Example("""
                    enum Foo {
                    }
                    struct Bar {
                    }
                    """,
                    configuration: ["ignored_types": ["enum", "struct"]]),
            Example("""
                    struct Foo {}
                    struct Bar {}
                    """,
                    configuration: ["ignored_types": ["struct"]]),
        ],
        triggeringExamples: [
            Example("""
                    class Foo {}
                    ↓class Bar {}
                    """),
            Example("""
                    protocol Foo {}
                    ↓enum Bar {}
                    """),
            Example("""
                    struct Foo {}
                    ↓struct Bar {}
                    """),
            Example("""
                    struct Foo {}
                    ↓enum Bar {}
                    """,
                    configuration: ["ignored_types": ["protocol"]]),
        ]
    )
}

private extension OneDeclarationPerFileRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private let allowedTypes: Set<String>
        private var declarationVisited = false
        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] { .all }

        override init(configuration: OneDeclarationPerFileConfiguration, file: SwiftLintFile) {
            allowedTypes = Set(configuration.allowedTypes.map(\.rawValue))
            super.init(configuration: configuration, file: file)
        }

        override func visitPost(_ node: ActorDeclSyntax) {
            appendViolationIfNeeded(node: node.actorKeyword)
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            appendViolationIfNeeded(node: node.classKeyword)
        }

        override func visitPost(_ node: StructDeclSyntax) {
            appendViolationIfNeeded(node: node.structKeyword)
        }

        override func visitPost(_ node: EnumDeclSyntax) {
            appendViolationIfNeeded(node: node.enumKeyword)
        }

        override func visitPost(_ node: ProtocolDeclSyntax) {
            appendViolationIfNeeded(node: node.protocolKeyword)
        }

        func appendViolationIfNeeded(node: TokenSyntax) {
            defer { declarationVisited = true }
            if declarationVisited && !allowedTypes.contains(node.text) {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}
