import SwiftSyntax

@SwiftSyntaxRule
struct NestingRule: Rule {
    var configuration = NestingConfiguration()

    static let description = RuleDescription(
        identifier: "nesting",
        name: "Nesting",
        description:
            "Types should be nested at most 1 level deep, and functions should be nested at most 2 levels deep.",
        kind: .metrics,
        nonTriggeringExamples: NestingRuleExamples.nonTriggeringExamples,
        triggeringExamples: NestingRuleExamples.triggeringExamples
    )
}

private struct ValidationData {
    private(set) var typeLevel: Int = -1
    private(set) var functionLevel: Int = -1
    private var declStack = Stack<any DeclSyntaxProtocol>()

    var isFunction: Bool {
        declStack.peek()?.is(FunctionDeclSyntax.self) ?? false
    }

    mutating func push(_ node: some DeclSyntaxProtocol) {
        declStack.push(node)
        updateLevel(with: 1)
    }

    mutating func pop() {
        updateLevel(with: -1)
        declStack.pop()
    }

    private mutating func updateLevel(with value: Int) {
        if isFunction {
            functionLevel += value
        } else {
            typeLevel += value
        }
    }
}

private extension NestingRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] { [ProtocolDeclSyntax.self] }

        private var validationData = ValidationData()

        override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
            validate(node, triggeringToken: node.actorKeyword, inFunction: validationData.isFunction)
            return .visitChildren
        }

        override func visitPost(_ node: ActorDeclSyntax) {
            validationData.pop()
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            validate(node, triggeringToken: node.classKeyword, inFunction: validationData.isFunction)
            return .visitChildren
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            validationData.pop()
        }

        override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
            validate(node, triggeringToken: node.enumKeyword, inFunction: validationData.isFunction)
            return .visitChildren
        }

        override func visitPost(_ node: EnumDeclSyntax) {
            validationData.pop()
        }

        override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
            validate(node, triggeringToken: node.extensionKeyword, inFunction: validationData.isFunction)
            return .visitChildren
        }

        override func visitPost(_ node: ExtensionDeclSyntax) {
            validationData.pop()
        }

        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            validate(node, triggeringToken: node.funcKeyword, inFunction: validationData.isFunction)
            return .visitChildren
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            validationData.pop()
        }

        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            validate(node, triggeringToken: node.structKeyword, inFunction: validationData.isFunction)
            return .visitChildren
        }

        override func visitPost(_ node: StructDeclSyntax) {
            validationData.pop()
        }

        // MARK: - configuration for ignoreTypealiasesAndAssociatedtypes
        override func visitPost(_ node: TypeAliasDeclSyntax) {
            guard !configuration.ignoreTypealiasesAndAssociatedtypes else { return }
            validate(node, triggeringToken: node.typealiasKeyword, inFunction: false)
            validationData.pop()
        }

        override func visitPost(_ node: AssociatedTypeDeclSyntax) {
            guard !configuration.ignoreTypealiasesAndAssociatedtypes else { return }
            validate(node, triggeringToken: node.associatedtypeKeyword, inFunction: false)
            validationData.pop()
        }

        // MARK: - configuration for checkNestingInClosuresAndStatements
        override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
            guard configuration.checkNestingInClosuresAndStatements else {
                return .skipChildren
            }
            return super.visit(node)
        }

        override func visit(_ node: CodeBlockItemSyntax) -> SyntaxVisitorContinueKind {
            if !configuration.checkNestingInClosuresAndStatements, node.parent?.inStatement ?? false {
                return .skipChildren
            }
            return super.visit(node)
        }

        // MARK: -
        private func validate(_ node: some DeclSyntaxProtocol, triggeringToken: TokenSyntax, inFunction: Bool) {
            validationData.push(node)
            let isFunction = validationData.isFunction
            let (level, targetLevel) =
                if isFunction {
                    (validationData.functionLevel, configuration.functionLevel)
                } else {
                    (validationData.typeLevel, configuration.typeLevel)
                }

            let violatingSeverity: ViolationSeverity? =
                if configuration.alwaysAllowOneTypeInFunctions, !inFunction {
                    configuration.severity(with: targetLevel, for: level)
                } else if isFunction || !configuration.alwaysAllowOneTypeInFunctions {
                    configuration.severity(with: targetLevel, for: level)
                } else {
                    nil
                }

            guard let severity = violatingSeverity else {
                return
            }

            let targetName = isFunction ? "Functions" : "Types"
            let threshold = configuration.threshold(with: targetLevel, for: severity)
            let pluralSuffix = threshold > 1 ? "s" : ""
            violations.append(ReasonedRuleViolation(
                position: triggeringToken.positionAfterSkippingLeadingTrivia,
                reason: "\(targetName) should be nested at most \(threshold) level\(pluralSuffix) deep",
                severity: severity
            ))
        }
    }
}

private extension Syntax {
    var inStatement: Bool {
        func isStatement(_ node: Syntax) -> Bool {
            node.isProtocol((any StmtSyntaxProtocol).self) || node.parent.map(isStatement) ?? false
        }
        return isStatement(self)
    }
}
