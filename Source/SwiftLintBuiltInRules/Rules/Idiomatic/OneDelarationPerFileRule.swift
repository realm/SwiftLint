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
}

private extension OneDelarationPerFileRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        var declarationsCount: Int = 0
        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
            return .allExcept(ClassDeclSyntax.self, StructDeclSyntax.self, EnumDeclSyntax.self, ProtocolDeclSyntax.self)
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            declarationsCount += 1
            appendViolationIfNeeded(node: node.name)
            return .skipChildren
        }

        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            declarationsCount += 1
            appendViolationIfNeeded(node: node.name)
            return .skipChildren
        }

        override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
            declarationsCount += 1
            appendViolationIfNeeded(node: node.name)
            return .skipChildren
        }

        override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
            declarationsCount += 1
            appendViolationIfNeeded(node: node.name)
            return .skipChildren
        }

        func appendViolationIfNeeded(node: TokenSyntax) {
            if declarationsCount > 1 {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}
