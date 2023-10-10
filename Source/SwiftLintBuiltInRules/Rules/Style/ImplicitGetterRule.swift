import SwiftSyntax

struct ImplicitGetterRule: ConfigurationProviderRule, SwiftSyntaxRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "implicit_getter",
        name: "Implicit Getter",
        description: "Computed read-only properties and subscripts should avoid using the get keyword.",
        kind: .style,
        nonTriggeringExamples: ImplicitGetterRuleExamples.nonTriggeringExamples,
        triggeringExamples: ImplicitGetterRuleExamples.triggeringExamples
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

extension ImplicitGetterRule {
    private enum ViolationKind {
        case `subscript`, property

        var violationDescription: String {
            switch self {
            case .subscript:
                return "Computed read-only subscripts should avoid using the get keyword"
            case .property:
                return "Computed read-only properties should avoid using the get keyword"
            }
        }
    }

    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: AccessorBlockSyntax) {
            guard let getAccessor = node.getAccessor,
                  node.setAccessor == nil,
                  getAccessor.effectSpecifiers == nil,
                  getAccessor.modifier == nil,
                  getAccessor.attributes.isEmpty == true,
                  getAccessor.body != nil else {
                return
            }

            let kind: ViolationKind = node.parent?.as(SubscriptDeclSyntax.self) == nil ? .property : .subscript
            violations.append(
                ReasonedRuleViolation(
                    position: getAccessor.positionAfterSkippingLeadingTrivia,
                    reason: kind.violationDescription
                )
            )
        }
    }
}
