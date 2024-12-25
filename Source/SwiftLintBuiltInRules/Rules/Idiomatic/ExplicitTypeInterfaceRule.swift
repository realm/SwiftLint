import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct ExplicitTypeInterfaceRule: Rule {
    var configuration = ExplicitTypeInterfaceConfiguration()

    static let description = RuleDescription(
        identifier: "explicit_type_interface",
        name: "Explicit Type Interface",
        description: "Properties should have a type interface",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("""
            class Foo {
              var myVar: Int? = 0
            }
            """),
            Example("""
            class Foo {
              let myVar: Int? = 0, s: String = ""
            }
            """),
            Example("""
            class Foo {
              static var myVar: Int? = 0
            }
            """),
            Example("""
            class Foo {
              class var myVar: Int? = 0
            }
            """),
            Example("""
            func f() {
                if case .failure(let error) = errorCompletion {}
            }
            """, excludeFromDocumentation: true),
        ],
        triggeringExamples: [
            Example("""
            class Foo {
              var ↓myVar = 0
            }
            """),
            Example("""
            class Foo {
              let ↓mylet = 0
            }
            """),
            Example("""
            class Foo {
              static var ↓myStaticVar = 0
            }
            """),
            Example("""
            class Foo {
              class var ↓myClassVar = 0
            }
            """),
            Example("""
            class Foo {
              let ↓myVar = Int(0), ↓s = ""
            }
            """),
            Example("""
            class Foo {
              let ↓myVar = Set<Int>(0)
            }
            """),
        ]
    )
}

private extension ExplicitTypeInterfaceRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] { [ProtocolDeclSyntax.self] }

        override func visitPost(_ node: VariableDeclSyntax) {
            if node.modifiers.contains(keyword: .class) {
                if configuration.allowedKinds.contains(.class) {
                    checkViolation(node)
                }
            } else if node.modifiers.contains(keyword: .static) {
                if configuration.allowedKinds.contains(.static) {
                    checkViolation(node)
                }
            } else if node.parent?.is(MemberBlockItemSyntax.self) == true {
                if configuration.allowedKinds.contains(.instance) {
                    checkViolation(node)
                }
            } else if node.parent?.is(CodeBlockItemSyntax.self) == true {
                if configuration.allowedKinds.contains(.local) {
                    checkViolation(node)
                }
            }
        }

        private func checkViolation(_ node: VariableDeclSyntax) {
            for binding in node.bindings {
                if configuration.allowRedundancy, let initializer = binding.initializer,
                   initializer.isTypeConstructor || initializer.isTypeReference {
                    continue
                }
                if binding.typeAnnotation == nil {
                    violations.append(binding.positionAfterSkippingLeadingTrivia)
                }
            }
        }
    }
}

private extension InitializerClauseSyntax {
    var isTypeConstructor: Bool {
        if value.as(FunctionCallExprSyntax.self)?.callsPotentialType == true {
            return true
        }
        if let tryExpr = value.as(TryExprSyntax.self),
           tryExpr.expression.as(FunctionCallExprSyntax.self)?.callsPotentialType == true {
            return true
        }
        return false
    }

    var isTypeReference: Bool {
        value.as(MemberAccessExprSyntax.self)?.declName.baseName.tokenKind == .keyword(.self)
    }
}

private extension FunctionCallExprSyntax {
    var callsPotentialType: Bool {
        let name = calledExpression.debugDescription
        return name.first?.isUppercase == true || (name.first == "[" && name.last == "]")
    }
}
