import SwiftSyntax

@SwiftSyntaxRule(foldExpressions: true, explicitRewriter: true, optIn: true)
struct RedundantNilCoalescingRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "redundant_nil_coalescing",
        name: "Redundant Nil Coalescing",
        description: "Coalescing operator with right-hand side nil is redundant",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("var myVar: Int?; myVar ?? 0"),
            Example("""
            func myFirstFunc() -> String?? {
                nil
            }
            func mySecondFunc() -> String? {
                return myFirstFunc() ?? nil
            }
            """),
        ],
        triggeringExamples: [
            Example("var myVar: Int? = nil; myVar ↓?? nil")
        ],
        corrections: [
            Example("var myVar: Int? = nil; let foo = myVar ↓?? nil"):
                Example("var myVar: Int? = nil; let foo = myVar"),
            Example("let a = b ?? nil // swiftlint:disable:this redundant_nil_coalescing"):
                Example("let a = b ?? nil // swiftlint:disable:this redundant_nil_coalescing"),
        ]
    )
}

private extension RedundantNilCoalescingRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private lazy var typeInfo = DoubleOptionalTypeInfoCollector.collect(from: file)

        override func visitPost(_ node: InfixOperatorExprSyntax) {
            guard node.operator.isNilCoalescingOperator,
                  node.rightOperand.is(NilLiteralExprSyntax.self),
                  !node.leftOperand.isDoubleOptional(using: typeInfo) else {
                return
            }

            violations.append(node.operator.positionAfterSkippingLeadingTrivia)
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        private lazy var typeInfo = DoubleOptionalTypeInfoCollector.collect(from: file)

        override func visit(_ node: InfixOperatorExprSyntax) -> ExprSyntax {
            guard node.operator.isNilCoalescingOperator,
                  node.rightOperand.is(NilLiteralExprSyntax.self),
                  !node.leftOperand.isDoubleOptional(using: typeInfo) else {
                return super.visit(node)
            }
            numberOfCorrections += 1
            return super.visit(node.leftOperand.with(\.trailingTrivia, []))
        }
    }
}

private struct DoubleOptionalTypeInfo {
    var functionReturnTypes = [String: TypeSyntax]()
    var variableTypes = [String: TypeSyntax]()
}

private enum DoubleOptionalTypeInfoCollector {
    static func collect(from file: SwiftLintFile) -> DoubleOptionalTypeInfo {
        DoubleOptionalTypeInfoVisitor(viewMode: .sourceAccurate)
            .walk(tree: file.syntaxTree, handler: \.typeInfo)
    }
}

private final class DoubleOptionalTypeInfoVisitor: SyntaxVisitor {
    private(set) var typeInfo = DoubleOptionalTypeInfo()

    override func visitPost(_ node: FunctionDeclSyntax) {
        if let returnType = node.signature.returnClause?.type {
            typeInfo.functionReturnTypes[node.name.text] = returnType
        }
    }

    override func visitPost(_ node: VariableDeclSyntax) {
        for binding in node.bindings {
            guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
                  let type = binding.typeAnnotation?.type else {
                continue
            }

            typeInfo.variableTypes[pattern.identifier.text] = type
        }
    }
}

private extension ExprSyntax {
    func isDoubleOptional(using typeInfo: DoubleOptionalTypeInfo) -> Bool {
        if let reference = `as`(DeclReferenceExprSyntax.self) {
            return typeInfo.variableTypes[reference.baseName.text]?.isDoubleOptional == true
        }

        if let call = `as`(FunctionCallExprSyntax.self),
           let name = call.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text {
            return typeInfo.functionReturnTypes[name]?.isDoubleOptional == true
        }

        return false
    }
}

private extension TypeSyntax {
    var isDoubleOptional: Bool {
        guard let optionalType = `as`(OptionalTypeSyntax.self) else {
            return false
        }

        return optionalType.wrappedType.is(OptionalTypeSyntax.self)
    }
}

private extension ExprSyntax {
    var isNilCoalescingOperator: Bool {
        `as`(BinaryOperatorExprSyntax.self)?.operator.tokenKind == .binaryOperator("??")
    }
}
