import SwiftSyntax

public struct ImplicitReturnRule: ConfigurationProviderRule, SwiftSyntaxCorrectableRule, OptInRule {
    public var configuration = ImplicitReturnConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "implicit_return",
        name: "Implicit Return",
        description: "Prefer implicit returns in closures, functions and getters.",
        kind: .style,
        nonTriggeringExamples: ImplicitReturnRuleExamples.nonTriggeringExamples,
        triggeringExamples: ImplicitReturnRuleExamples.triggeringExamples,
        corrections: ImplicitReturnRuleExamples.corrections
    )

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(includedKinds: configuration.includedKinds)
    }

    public func makeRewriter(file: SwiftLintFile) -> ViolationsSyntaxRewriter? {
        Rewriter(
            includedKinds: configuration.includedKinds,
            locationConverter: file.locationConverter,
            disabledRegions: disabledRegions(file: file)
        )
    }
}

private extension ImplicitReturnRule {
    final class Visitor: ViolationsSyntaxVisitor {
        private let includedKinds: Set<ImplicitReturnConfiguration.ReturnKind>

        init(includedKinds: Set<ImplicitReturnConfiguration.ReturnKind>) {
            self.includedKinds = includedKinds
            super.init(viewMode: .sourceAccurate)
        }

        override func visitPost(_ node: ClosureExprSyntax) {
            guard includedKinds.contains(.closure),
                  let statement = node.statements.onlyElement,
                  statement.item.is(ReturnStmtSyntax.self) else {
                return
            }

            violations.append(statement.item.positionAfterSkippingLeadingTrivia)
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            guard includedKinds.contains(.function),
                  let statement = node.body?.statements.onlyElement,
                  statement.item.is(ReturnStmtSyntax.self) else {
                return
            }

            violations.append(statement.item.positionAfterSkippingLeadingTrivia)
        }

        override func visitPost(_ node: VariableDeclSyntax) {
            guard includedKinds.contains(.getter) else {
                return
            }

            for binding in node.bindings {
                switch binding.accessor {
                case nil:
                    continue
                case .accessors(let accessors):
                    if let statement = accessors.getAccessor?.body?.statements.onlyElement,
                       let returnStmt = statement.item.as(ReturnStmtSyntax.self) {
                        violations.append(returnStmt.positionAfterSkippingLeadingTrivia)
                    }
                case .getter(let getter):
                    if let returnStmt = getter.statements.onlyElement?.item.as(ReturnStmtSyntax.self) {
                        violations.append(returnStmt.positionAfterSkippingLeadingTrivia)
                    }
                }
            }
        }
    }

    final class Rewriter: SyntaxRewriter, ViolationsSyntaxRewriter {
        private(set) var correctionPositions: [AbsolutePosition] = []
        private let includedKinds: Set<ImplicitReturnConfiguration.ReturnKind>
        private let locationConverter: SourceLocationConverter
        private let disabledRegions: [SourceRange]

        init(includedKinds: Set<ImplicitReturnConfiguration.ReturnKind>,
             locationConverter: SourceLocationConverter,
             disabledRegions: [SourceRange]) {
            self.includedKinds = includedKinds
            self.locationConverter = locationConverter
            self.disabledRegions = disabledRegions
        }

        override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
            guard includedKinds.contains(.closure),
                  let statement = node.statements.onlyElement,
                  let returnStmt = statement.item.as(ReturnStmtSyntax.self),
                  let expr = returnStmt.expression,
                  !returnStmt.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) else {
                return super.visit(node)
            }

            correctionPositions.append(returnStmt.positionAfterSkippingLeadingTrivia)

            let newNode = node.withStatements([
                statement
                    .withItem(.expr(expr))
                    .withLeadingTrivia(returnStmt.leadingTrivia ?? .zero)
            ])
            return super.visit(newNode)
        }

        override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
            guard includedKinds.contains(.function),
                  let statement = node.body?.statements.onlyElement,
                  let returnStmt = statement.item.as(ReturnStmtSyntax.self),
                  let expr = returnStmt.expression,
                  !returnStmt.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) else {
                return super.visit(node)
            }

            correctionPositions.append(returnStmt.positionAfterSkippingLeadingTrivia)

            let newNode = node.withBody(node.body?.withStatements([
                statement
                    .withItem(.expr(expr))
                    .withLeadingTrivia(returnStmt.leadingTrivia ?? .zero)
            ]))
            return super.visit(newNode)
        }

        override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
            guard includedKinds.contains(.getter) else {
                return super.visit(node)
            }

            let updatedBindings: [PatternBindingSyntax] = node.bindings.map { binding in
                switch binding.accessor {
                case nil:
                    return binding
                case .accessors(let accessorBlock):
                    guard let getAccessor = accessorBlock.getAccessor,
                          let statement = accessorBlock.getAccessor?.body?.statements.onlyElement,
                          let returnStmt = statement.item.as(ReturnStmtSyntax.self),
                          !returnStmt.isContainedIn(regions: disabledRegions, locationConverter: locationConverter),
                          let expr = returnStmt.expression else {
                        break
                    }

                    correctionPositions.append(returnStmt.positionAfterSkippingLeadingTrivia)

                    let updatedGetAcessor = getAccessor.withBody(getAccessor.body?.withStatements([
                        statement
                            .withItem(.expr(expr))
                            .withLeadingTrivia(returnStmt.leadingTrivia ?? .zero)
                    ]))
                    let updatedAccessors = accessorBlock
                        .withAccessors(
                            accessorBlock.accessors.replacing(
                                childAt: getAccessor.indexInParent,
                                with: updatedGetAcessor
                            )
                        )
                    return binding.withAccessor(.accessors(updatedAccessors))
                case .getter(let getter):
                    guard let statement = getter.statements.onlyElement,
                          let returnStmt = statement.item.as(ReturnStmtSyntax.self),
                          !returnStmt.isContainedIn(regions: disabledRegions, locationConverter: locationConverter),
                          let expr = returnStmt.expression else {
                        break
                    }

                    correctionPositions.append(returnStmt.positionAfterSkippingLeadingTrivia)
                    return binding.withAccessor(.getter(getter.withStatements([
                        statement
                            .withItem(.expr(expr))
                            .withLeadingTrivia(returnStmt.leadingTrivia ?? .zero)
                    ])))
                }

                return binding
            }

            return super.visit(node.withBindings(PatternBindingListSyntax(updatedBindings)))
        }
    }
}
