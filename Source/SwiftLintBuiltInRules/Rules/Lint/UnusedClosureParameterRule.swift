import SwiftSyntax
import SwiftSyntaxBuilder

@SwiftSyntaxRule(explicitRewriter: true)
struct UnusedClosureParameterRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "unused_closure_parameter",
        name: "Unused Closure Parameter",
        description: "Unused parameter in a closure should be replaced with _",
        kind: .lint,
        nonTriggeringExamples: UnusedClosureParameterRuleExamples.nonTriggering,
        triggeringExamples: UnusedClosureParameterRuleExamples.triggering,
        corrections: UnusedClosureParameterRuleExamples.corrections
    )
}

private extension UnusedClosureParameterRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: ClosureExprSyntax) {
            let namedParameters = node.namedParameters
            guard namedParameters.isNotEmpty else {
                return
            }

            let referencedIdentifiers = IdentifierReferenceVisitor(viewMode: .sourceAccurate)
                .walk(tree: node.statements, handler: \.identifiers)

            for parameter in namedParameters where !referencedIdentifiers.contains(parameter.name) {
                violations.append(parameter.position)
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
            guard node.namedParameters.isNotEmpty,
                  let signature = node.signature,
                  let input = signature.parameterClause else {
                return super.visit(node)
            }

            let referencedIdentifiers = IdentifierReferenceVisitor(viewMode: .sourceAccurate)
                .walk(tree: node.statements, handler: \.identifiers)

            guard let params = input.as(ClosureShorthandParameterListSyntax.self) else {
                guard let params = input.as(ClosureParameterClauseSyntax.self) else {
                    return super.visit(node)
                }
                var newParams = params
                for param in params.parameters {
                    let name = param.firstName
                    guard name.tokenKind != .wildcard,
                          !referencedIdentifiers.contains(name.text.removingDollarsAndBackticks),
                          let index = params.parameters.index(of: param) else {
                        continue
                    }
                    correctionPositions.append(name.positionAfterSkippingLeadingTrivia)
                    let newParameterList = newParams.parameters.with(
                        \.[index],
                        param.with(\.firstName, name.with(\.tokenKind, .wildcard))
                    )
                    newParams = newParams.with(\.parameters, newParameterList)
                }
                let newNode = node.with(\.signature, signature.with(\.parameterClause, .init(newParams)))
                return super.visit(newNode)
            }

            var newParams = params
            for param in params {
                guard param.name.tokenKind != .wildcard,
                      !referencedIdentifiers.contains(param.name.text.removingDollarsAndBackticks),
                      let index = params.index(of: param) else {
                    continue
                }
                correctionPositions.append(param.name.positionAfterSkippingLeadingTrivia)
                newParams = newParams.with(
                    \.[index],
                    param.with(\.name, param.name.with(\.tokenKind, .wildcard))
                )
            }
            let newNode = node.with(\.signature, signature.with(\.parameterClause, .init(newParams)))
            return super.visit(newNode)
        }
    }
}

private final class IdentifierReferenceVisitor: SyntaxVisitor {
    private(set) var identifiers: Set<String> = []

    override func visitPost(_ node: DeclReferenceExprSyntax) {
        if node.keyPathInParent != \MemberAccessExprSyntax.declName {
            identifiers.insert(node.baseName.text.removingDollarsAndBackticks)
        }
    }
}

private extension String {
    var removingDollarsAndBackticks: String {
        self.replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "`", with: "")
    }
}

private struct ClosureParam {
    let position: AbsolutePosition
    let name: String
}

private extension ClosureExprSyntax {
    var namedParameters: [ClosureParam] {
        if let params = signature?.parameterClause?.as(ClosureShorthandParameterListSyntax.self) {
            return params.compactMap { param in
                if param.name.tokenKind == .wildcard {
                    return nil
                }
                return ClosureParam(
                    position: param.name.positionAfterSkippingLeadingTrivia,
                    name: param.name.text.removingDollarsAndBackticks
                )
            }
        }
        if let params = signature?.parameterClause?.as(ClosureParameterClauseSyntax.self)?.parameters {
            return params.compactMap { param in
                if param.firstName.tokenKind == .wildcard {
                    return nil
                }
                return ClosureParam(
                    position: param.firstName.positionAfterSkippingLeadingTrivia,
                    name: param.firstName.text.removingDollarsAndBackticks
                )
            }
        }
        return []
    }
}
