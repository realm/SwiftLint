import Foundation
import SwiftSyntax

@SwiftSyntaxRule
struct OneDelarationPerFileRule: Rule {
    var configuration = SeverityConfiguration<Self>(.error)

    static let description = RuleDescription(
        identifier: "one_declaration_per_file",
        name: "One Declaration Per File",
        description: "One declaration per file is allowed, extensions are an exception",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("""
                    class Car {
                        var make: String
                        var model: String
                        init(make: String, model: String) {
                            self.make = make
                            self.model = model
                        }
                    }
                    """),
            Example("""
                    class Car {
                        var make: String
                        var model: String
                        init(make: String, model: String) {
                            self.make = make
                            self.model = model
                        }
                    }
                    extension Car {
                        func drive() {
                        }
                        func stop() {
                        }
                    }
                    """)
        ],
        triggeringExamples: [
            Example("""
                    class Car {
                        var make: String
                        var model: String
                        init(make: String, model: String) {
                            self.make = make
                            self.model = model
                        }
                    }
                    class Bike {
                        func ride() {
                        }
                        func stop() {
                        }
                    }
                    """),
            Example("""
                    protocol Identifiable {
                        var identifier: String { get }
                    }
                    enum IdentifiableTypes: String {
                        case linear, composite
                    }
                    """),
            Example("""
                    struct BasicProfile {
                        var id: Int
                        var name: String
                    }
                    struct DetailedProfile {
                        var basic: BasicProfile
                        var age: String
                        var genderRaw: String
                    }
                    """)
        ]
    )

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        let visitor = Visitor(configuration: configuration, file: file)
        visitor.walk(file.syntaxTree)

        for (index, token) in visitor.tokens.enumerated() where index > 0 {
            visitor.violations.append(token.positionAfterSkippingLeadingTrivia)
        }

        return visitor.violations.map { violation in
            makeViolation(file: file,
                          violation: violation)
        }
    }
}

private extension OneDelarationPerFileRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        var tokens: [TokenSyntax] = []

        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
            return .allExcept(ClassDeclSyntax.self, StructDeclSyntax.self, EnumDeclSyntax.self, ProtocolDeclSyntax.self)
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            tokens.append(node.name)
            return .skipChildren
        }

        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            tokens.append(node.name)
            return .skipChildren
        }

        override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
            tokens.append(node.name)
            return .skipChildren
        }

        override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
            tokens.append(node.name)
            return .skipChildren
        }
    }
}
