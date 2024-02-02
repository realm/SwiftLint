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
    private var typeLevel: Int = -1
    private var functionLevel: Int = -1
    private var functionOrNotStack = Stack<Bool>()

    private var lastIsFunction: Bool { functionOrNotStack.peek() == true }

    mutating func validate(
        forFunction: Bool,
        with configuration: NestingConfiguration
    ) -> (ViolationSeverity, String)? {
        let inFunction = lastIsFunction
        push(forFunction)

        let level = forFunction ? functionLevel : typeLevel
        let targetLevel = forFunction ? configuration.functionLevel : configuration.typeLevel

        // if parent is function and current is not function types, then skip nesting rule.
        if configuration.alwaysAllowOneTypeInFunctions && inFunction && !forFunction {
            return nil
        }
        guard let severity = configuration.severity(with: targetLevel, for: level) else { return nil }
        let threshold = configuration.threshold(with: targetLevel, for: severity)

        let targetName = forFunction ? "Functions" : "Types"
        let pluralSuffix = threshold > 1 ? "s" : ""
        return (severity, "\(targetName) should be nested at most \(threshold) level\(pluralSuffix) deep")
    }

    private mutating func push(_ isFunction: Bool) {
        functionOrNotStack.push(isFunction)
        updateLevel(with: 1)
    }

    mutating func pop() {
        updateLevel(with: -1)
        functionOrNotStack.pop()
    }

    private mutating func updateLevel(with value: Int) {
        if lastIsFunction {
            functionLevel += value
        } else {
            typeLevel += value
        }
    }
}

private extension NestingRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
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

        override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
            validate(forFunction: false, triggeringToken: node.protocolKeyword)
            return .visitChildren
        }

        override func visitPost(_ node: ProtocolDeclSyntax) {
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
            if configuration.ignoreTypealiasesAndAssociatedtypes {
                return
            }
            validate(forFunction: false, triggeringToken: node.typealiasKeyword)
            levels.pop()
        }

        override func visitPost(_ node: AssociatedTypeDeclSyntax) {
            if configuration.ignoreTypealiasesAndAssociatedtypes {
                return
            }
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
            guard let (severity, reason) = levels.validate(forFunction: forFunction, with: configuration) else {
                return
            }

            violations.append(ReasonedRuleViolation(
                position: triggeringToken.positionAfterSkippingLeadingTrivia,
                reason: reason,
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
