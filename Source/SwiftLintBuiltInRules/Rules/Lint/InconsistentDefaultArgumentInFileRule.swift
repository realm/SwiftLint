import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct InconsistentDefaultArgumentInFileRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "inconsistent_default_argument_in_file",
        name: "Inconsistent Default Argument in File",
        description: """
            Overloaded functions declared on the same type (its primary declaration and any extensions of it in \
            the same file) should not use different default values for a shared parameter, as this is usually an \
            accidental drift that callers do not expect
            """,
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
            struct S {
              func f(x: Int = 1) {}
            }
            """),
            Example("""
            struct S {
              func f(x: Int = 1) {}
              func f(x: Int = 1, y: Int) {}
            }
            """),
            Example("""
            struct S {
              func f(x: Int = 1) {}
              func f(x: Int, y: Int) {}
            }
            """),
            Example("""
            struct S {
              func f(x: Int = 1) {}
              func f(x: String = "") {}
            }
            """),
            Example("""
            struct S {
              func f(x: Int = 1) {}
              func g(x: Int = 2) {}
            }
            """),
            Example("""
            struct A {
              func f(x: Int = 1) {}
            }
            struct B {
              func f(x: Int = 2) {}
            }
            """),
            Example("""
            struct Outer {
              func f(x: Int = 1) {}
              struct Inner {
                func f(x: Int = 2) {}
              }
            }
            """),
        ],
        triggeringExamples: [
            Example("""
            struct S {
              func f(x: Int = 1) {}
              func f(↓x: Int = 2, y: Int) {}
            }
            """),
            Example("""
            struct Network {
              func fetch(_ url: URL, retries: Int = 3) {}
              func fetch(_ url: URL, headers: [String: String], ↓retries: Int = 0) {}
            }
            """),
            Example("""
            struct V {
              func animate(_ c: () -> Void, duration: TimeInterval = 0.3) {}
              func animate(_ c: () -> Void, ↓duration: TimeInterval = 0.25, completion: () -> Void) {}
            }
            """),
            Example("""
            struct S {
              func f(x: Int = 1) {}
            }
            extension S {
              func f(↓x: Int = 2, y: Int) {}
            }
            """),
        ]
    )
}

/// A single parameter declaration that carries a default value.
private struct DefaultedParameter {
    let label: String
    let type: String
    let defaultValue: String
    let position: AbsolutePosition
}

private extension InconsistentDefaultArgumentInFileRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        /// Defaulted parameters collected per type scope, then per function base name.
        ///
        /// The scope key is the fully-qualified lexical type name (e.g. `Foo.Bar`), so a type's primary
        /// declaration and any extensions of it in the same file share an entry, while nested types form
        /// their own scope.
        private var scopes: [String: [String: [DefaultedParameter]]] = [:]

        override func visitPost(_ node: StructDeclSyntax) {
            collect(node.memberBlock.members, in: node)
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            collect(node.memberBlock.members, in: node)
        }

        override func visitPost(_ node: EnumDeclSyntax) {
            collect(node.memberBlock.members, in: node)
        }

        override func visitPost(_ node: ActorDeclSyntax) {
            collect(node.memberBlock.members, in: node)
        }

        override func visitPost(_ node: ProtocolDeclSyntax) {
            collect(node.memberBlock.members, in: node)
        }

        override func visitPost(_ node: ExtensionDeclSyntax) {
            collect(node.memberBlock.members, in: node)
        }

        override func visitPost(_: SourceFileSyntax) {
            for (_, functions) in scopes.sorted(by: { $0.key < $1.key }) {
                for (_, parameters) in functions.sorted(by: { $0.key < $1.key }) {
                    collectViolations(for: parameters)
                }
            }
        }

        /// Collects the defaulted parameters of the directly-declared functions of a type scope.
        private func collect(_ members: MemberBlockItemListSyntax, in decl: some DeclSyntaxProtocol) {
            let scope = scopeName(for: decl)
            for function in members.compactMap({ $0.decl.as(FunctionDeclSyntax.self) }) {
                let name = function.name.text
                for parameter in function.signature.parameterClause.parameters {
                    guard let defaultValue = parameter.defaultValue?.value else {
                        continue
                    }
                    scopes[scope, default: [:]][name, default: []].append(
                        DefaultedParameter(
                            label: parameter.firstName.text,
                            type: parameter.type.trimmedDescription,
                            defaultValue: defaultValue.trimmedDescription,
                            position: parameter.positionAfterSkippingLeadingTrivia
                        )
                    )
                }
            }
        }

        /// Flags parameters whose default diverges from the first declaration of a shared `(label, type)`.
        private func collectViolations(for parameters: [DefaultedParameter]) {
            let groups = Dictionary(grouping: parameters) { "\($0.label)|\($0.type)" }
            for group in groups.values where group.count > 1 {
                let ordered = group.sorted { $0.position < $1.position }
                guard let reference = ordered.first?.defaultValue else {
                    continue
                }
                for parameter in ordered where parameter.defaultValue != reference {
                    violations.append(parameter.position)
                }
            }
        }

        /// Builds the fully-qualified lexical type name for a declaration by walking its ancestors.
        private func scopeName(for decl: some DeclSyntaxProtocol) -> String {
            var components: [String] = []
            var current: Syntax? = Syntax(decl)
            while let node = current {
                if let type = node.as(StructDeclSyntax.self) {
                    components.append(type.name.text)
                } else if let type = node.as(ClassDeclSyntax.self) {
                    components.append(type.name.text)
                } else if let type = node.as(EnumDeclSyntax.self) {
                    components.append(type.name.text)
                } else if let type = node.as(ActorDeclSyntax.self) {
                    components.append(type.name.text)
                } else if let type = node.as(ProtocolDeclSyntax.self) {
                    components.append(type.name.text)
                } else if let ext = node.as(ExtensionDeclSyntax.self) {
                    components.append(ext.extendedType.trimmedDescription)
                }
                current = node.parent
            }
            return components.reversed().joined(separator: ".")
        }
    }
}
