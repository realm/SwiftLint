import SwiftSyntax

struct ExplicitTypeInterfaceRule: OptInRule, ConfigurationProviderRule, SwiftSyntaxRule {
    var configuration = ExplicitTypeInterfaceConfiguration()

    init() {}

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
            """, excludeFromDocumentation: true)
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
            """)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(configuration: configuration)
    }
}

private class Visitor: ViolationsSyntaxVisitor {
    let configuration: ExplicitTypeInterfaceConfiguration

    override var skippableDeclarations: [DeclSyntaxProtocol.Type] { [ProtocolDeclSyntax.self] }

    init(configuration: ExplicitTypeInterfaceConfiguration) {
        self.configuration = configuration
        super.init(viewMode: .sourceAccurate)
    }

    override func visitPost(_ node: VariableDeclSyntax) {
        if node.modifiers.isClass {
            if configuration.allowedKinds.contains(.class) {
                checkViolation(node)
            }
        } else if node.modifiers.isStatic {
            if configuration.allowedKinds.contains(.static) {
                checkViolation(node)
            }
        } else if node.parent?.is(MemberDeclListItemSyntax.self) == true {
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
        value.as(MemberAccessExprSyntax.self)?.name.tokenKind == .keyword(.self)
    }
}

private extension FunctionCallExprSyntax {
    var callsPotentialType: Bool {
        let name = calledExpression.debugDescription
        return name.first?.isUppercase == true || (name.first == "[" && name.last == "]")
    }
}
