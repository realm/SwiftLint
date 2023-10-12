import SwiftSyntax

@SwiftSyntaxRule(needsConfiguration: true)
struct ComputedAccessorsOrderRule: Rule {
    var configuration = ComputedAccessorsOrderConfiguration()

    static let description = RuleDescription(
        identifier: "computed_accessors_order",
        name: "Computed Accessors Order",
        description: "Getter and setters in computed properties and subscripts should be in a consistent order.",
        kind: .style,
        nonTriggeringExamples: ComputedAccessorsOrderRuleExamples.nonTriggeringExamples,
        triggeringExamples: ComputedAccessorsOrderRuleExamples.triggeringExamples
    )
}

private extension ComputedAccessorsOrderRule {
    private enum ViolationKind {
        case `subscript`, property
    }

    final class Visitor: ViolationsSyntaxVisitor {
        private let configuration: ConfigurationType

        init(configuration: ConfigurationType) {
            self.configuration = configuration
            super.init(viewMode: .sourceAccurate)
        }

        override func visitPost(_ node: AccessorBlockSyntax) {
            guard let firstAccessor = node.accessorsList.first,
                  let order = node.order,
                  order != configuration.order else {
                return
            }

            let kind: ViolationKind = node.parent?.as(SubscriptDeclSyntax.self) == nil ? .property : .subscript
            violations.append(
                ReasonedRuleViolation(
                    position: firstAccessor.positionAfterSkippingLeadingTrivia,
                    reason: reason(for: kind)
                )
            )
        }

        private func reason(for kind: ViolationKind) -> String {
            let kindString = kind == .subscript ? "subscripts" : "properties"
            let orderString: String
            switch configuration.order {
            case .getSet:
                orderString = "getter and then the setter"
            case .setGet:
                orderString = "setter and then the getter"
            }
            return "Computed \(kindString) should first declare the \(orderString)"
        }
    }
}

private extension AccessorBlockSyntax {
    var order: ComputedAccessorsOrderConfiguration.Order? {
        guard accessorsList.count == 2, accessorsList.map(\.body).allSatisfy({ $0 != nil }) else {
            return nil
        }

        let tokens = accessorsList.map(\.accessorSpecifier.tokenKind)
        if tokens == [.keyword(.get), .keyword(.set)] {
            return .getSet
        }

        if tokens == [.keyword(.set), .keyword(.get)] {
            return .setGet
        }

        return nil
    }
}
