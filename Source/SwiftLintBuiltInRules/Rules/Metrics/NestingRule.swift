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

private struct Levels {
    private(set) var typeLevel: Int = -1
    private(set) var functionLevel: Int = -1
    private(set) var functionOrNotStack = Stack<Bool>()

    mutating func push(_ isFunction: Bool) {
        functionOrNotStack.push(isFunction)
        updateLevel(with: 1, isFunction: isFunction)
    }

    mutating func pop() {
        updateLevel(with: -1, isFunction: functionOrNotStack.pop()!)
    }

    private mutating func updateLevel(with value: Int, isFunction: Bool) {
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

        private var levels = Levels()

        override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
            validate(forFunction: false, triggeringToken: node.actorKeyword)
            return .visitChildren
        }

        override func visitPost(_ node: ActorDeclSyntax) {
            levels.pop()
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            validate(forFunction: false, triggeringToken: node.classKeyword)
            return .visitChildren
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            levels.pop()
        }

        override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
            validate(forFunction: false, triggeringToken: node.enumKeyword)
            return .visitChildren
        }

        override func visitPost(_ node: EnumDeclSyntax) {
            levels.pop()
        }

        override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
            validate(forFunction: false, triggeringToken: node.extensionKeyword)
            return .visitChildren
        }

        override func visitPost(_ node: ExtensionDeclSyntax) {
            levels.pop()
        }

        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            validate(forFunction: true, triggeringToken: node.funcKeyword)
            return .visitChildren
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            levels.pop()
        }

        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            validate(forFunction: false, triggeringToken: node.structKeyword)
            return .visitChildren
        }

        override func visitPost(_ node: StructDeclSyntax) {
            levels.pop()
        }

        // MARK: - configuration for ignoreTypealiasesAndAssociatedtypes
        override func visitPost(_ node: TypeAliasDeclSyntax) {
            guard !configuration.ignoreTypealiasesAndAssociatedtypes else { return }
            validate(forFunction: false, triggeringToken: node.typealiasKeyword)
            levels.pop()
        }

        override func visitPost(_ node: AssociatedTypeDeclSyntax) {
            guard !configuration.ignoreTypealiasesAndAssociatedtypes else { return }
            validate(forFunction: false, triggeringToken: node.associatedtypeKeyword)
            levels.pop()
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
        private func validate(forFunction: Bool, triggeringToken: TokenSyntax) {
            let inFunction = levels.functionOrNotStack.peek() == true
            levels.push(forFunction)

            let (level, targetLevel) =
                if forFunction {
                    (levels.functionLevel, configuration.functionLevel)
                } else {
                    (levels.typeLevel, configuration.typeLevel)
                }

            let violatingSeverity: ViolationSeverity? =
                if configuration.alwaysAllowOneTypeInFunctions, !inFunction {
                    configuration.severity(with: targetLevel, for: level)
                } else if forFunction || !configuration.alwaysAllowOneTypeInFunctions {
                    configuration.severity(with: targetLevel, for: level)
                } else {
                    nil
                }

            guard let severity = violatingSeverity else {
                return
            }

            let targetName = forFunction ? "Functions" : "Types"
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
