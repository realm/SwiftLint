import SwiftSyntax

struct ImplicitReturnRule: SwiftSyntaxCorrectableRule, ConfigurationProviderRule, OptInRule {
    var configuration = ImplicitReturnConfiguration()

    static let description = RuleDescription(
        identifier: "implicit_return",
        name: "Implicit Return",
        description: "Prefer implicit returns in closures, functions and getters",
        kind: .style,
        nonTriggeringExamples: ImplicitReturnRuleExamples.nonTriggeringExamples,
        triggeringExamples: ImplicitReturnRuleExamples.triggeringExamples,
        corrections: ImplicitReturnRuleExamples.corrections
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(config: configuration)
    }
}

private extension ImplicitReturnRule {
    final class Visitor: ViolationsSyntaxVisitor {
        private let config: ConfigurationType

        override var skippableDeclarations: [DeclSyntaxProtocol.Type] { [ProtocolDeclSyntax.self] }

        init(config: ConfigurationType) {
            self.config = config
            super.init(viewMode: .sourceAccurate)
        }

        override func visitPost(_ node: AccessorDeclSyntax) {
            if config.isKindIncluded(.getter),
               node.accessorSpecifier.tokenKind == .keyword(.get),
               let body = node.body {
                collectViolation(in: body.statements)
            }
        }

        override func visitPost(_ node: ClosureExprSyntax) {
            if config.isKindIncluded(.closure) {
                collectViolation(in: node.statements)
            }
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            if config.isKindIncluded(.function),
               let body = node.body {
                collectViolation(in: body.statements)
            }
        }

        override func visitPost(_ node: InitializerDeclSyntax) {
            if config.isKindIncluded(.initializer),
               let body = node.body {
                collectViolation(in: body.statements)
            }
        }

        override func visitPost(_ node: PatternBindingSyntax) {
            if config.isKindIncluded(.getter),
               case let .getter(itemList) = node.accessorBlock?.accessors {
                collectViolation(in: itemList)
            }
        }

        override func visitPost(_ node: SubscriptDeclSyntax) {
            if config.isKindIncluded(.subscript),
               case let .getter(itemList) = node.accessorBlock?.accessors {
                collectViolation(in: itemList)
            }
        }

        private func collectViolation(in itemList: CodeBlockItemListSyntax) {
            guard let returnStmt = itemList.onlyElement?.item.as(ReturnStmtSyntax.self) else {
                return
            }
            let returnKeyword = returnStmt.returnKeyword
            violations.append(returnKeyword.positionAfterSkippingLeadingTrivia)
            violationCorrections.append(
                ViolationCorrection(
                    start: returnKeyword.positionAfterSkippingLeadingTrivia,
                    end: returnKeyword.endPositionBeforeTrailingTrivia
                            .advanced(by: returnStmt.expression == nil ? 0 : 1),
                    replacement: ""
                )
            )
        }
    }
}
