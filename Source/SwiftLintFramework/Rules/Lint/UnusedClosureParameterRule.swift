import SwiftSyntax
import SwiftSyntaxBuilder

struct UnusedClosureParameterRule: SwiftSyntaxCorrectableRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "unused_closure_parameter",
        name: "Unused Closure Parameter",
        description: "Unused parameter in a closure should be replaced with _.",
        kind: .lint,
        nonTriggeringExamples: UnusedClosureParameterRuleExamples.nonTriggering,
        triggeringExamples: UnusedClosureParameterRuleExamples.triggering,
        corrections: UnusedClosureParameterRuleExamples.corrections
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }

    func makeRewriter(file: SwiftLintFile) -> ViolationsSyntaxRewriter? {
        Rewriter(
            locationConverter: file.locationConverter,
            disabledRegions: disabledRegions(file: file)
        )
    }
}

private extension UnusedClosureParameterRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: ClosureExprSyntax) {
            let namedParameters = node.namedParameters
            guard namedParameters.isNotEmpty else {
                return
            }

            let referencedIdentifiers = IdentifierReferenceVisitor(viewMode: .sourceAccurate)
                .walk(tree: node.statements, handler: \.identifiers)

            for parameter in namedParameters where !referencedIdentifiers.contains(parameter.name) {
                let violation = ReasonedRuleViolation(
                    position: parameter.position,
                    reason: #"Unused parameter "\#(parameter.name)" in a closure should be replaced with _."#
                )
                violations.append(violation)
            }
        }
    }

    final class Rewriter: SyntaxRewriter, ViolationsSyntaxRewriter {
        private(set) var correctionPositions: [AbsolutePosition] = []
        let locationConverter: SourceLocationConverter
        let disabledRegions: [SourceRange]

        init(locationConverter: SourceLocationConverter, disabledRegions: [SourceRange]) {
            self.locationConverter = locationConverter
            self.disabledRegions = disabledRegions
        }

        override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
            guard
                node.namedParameters.isNotEmpty,
                let signature = node.signature,
                let input = signature.input,
                !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter)
            else {
                return super.visit(node)
            }

            let referencedIdentifiers = IdentifierReferenceVisitor(viewMode: .sourceAccurate)
                .walk(tree: node.statements, handler: \.identifiers)

            guard let params = input.as(ClosureParamListSyntax.self) else {
                guard let params = input.as(ParameterClauseSyntax.self) else {
                    return super.visit(node)
                }

                var newParams = params
                for (index, param) in params.parameterList.enumerated() {
                    guard let name = param.firstName else {
                        continue
                    }

                    if name.tokenKind == .wildcardKeyword {
                        continue
                    } else if referencedIdentifiers.contains(name.text.removingDollarPrefix) {
                        continue
                    }

                    correctionPositions.append(name.positionAfterSkippingLeadingTrivia)
                    newParams = newParams.withParameterList(
                        newParams.parameterList.replacing(
                            childAt: index,
                            with: param.withFirstName(name.withKind(.wildcardKeyword))
                        )
                    )
                }
                let newNode = node.withSignature(signature.withInput(.init(newParams)))
                return super.visit(newNode)
            }

            var newParams = params
            for (index, param) in params.enumerated() {
                if param.name.tokenKind == .wildcardKeyword {
                    continue
                } else if referencedIdentifiers.contains(param.name.text.removingDollarPrefix) {
                    continue
                }

                correctionPositions.append(param.name.positionAfterSkippingLeadingTrivia)
                newParams = newParams.replacing(
                    childAt: index,
                    with: param.withName(param.name.withKind(.wildcardKeyword))
                )
            }
            let newNode = node.withSignature(signature.withInput(.init(newParams)))
            return super.visit(newNode)
        }
    }
}

private final class IdentifierReferenceVisitor: SyntaxVisitor {
    private(set) var identifiers: Set<String> = []

    override func visitPost(_ node: IdentifierExprSyntax) {
        identifiers.insert(node.identifier.text.removingDollarPrefix)
    }
}

private extension String {
    var removingDollarPrefix: String {
        replacingOccurrences(of: "$", with: "")
    }
}

private struct ClosureParam {
    let position: AbsolutePosition
    let name: String
}

private extension ClosureExprSyntax {
    var namedParameters: [ClosureParam] {
        if let params = signature?.input?.as(ClosureParamListSyntax.self) {
            return params.compactMap { param in
                if param.name.tokenKind == .wildcardKeyword {
                    return nil
                }
                return ClosureParam(
                    position: param.name.positionAfterSkippingLeadingTrivia,
                    name: param.name.text.removingDollarPrefix
                )
            }
        } else if let params = signature?.input?.as(ParameterClauseSyntax.self)?.parameterList {
            return params.compactMap { param in
                if param.firstName?.tokenKind == .wildcardKeyword {
                    return nil
                }
                return param.firstName.map { name in
                    ClosureParam(
                        position: name.positionAfterSkippingLeadingTrivia,
                        name: name.text.removingDollarPrefix
                    )
                }
            }
        } else {
            return []
        }
    }
}
