import SwiftSyntax

struct ComputedAccessorsOrderRule: ConfigurationProviderRule, SwiftSyntaxRule {
    var configuration = ComputedAccessorsOrderConfiguration()

    static let description = RuleDescription(
        identifier: "computed_accessors_order",
        name: "Computed Accessors Order",
        description: "Getter and setters in computed properties and subscripts should be in a consistent order.",
        kind: .style,
        nonTriggeringExamples: ComputedAccessorsOrderRuleExamples.nonTriggeringExamples,
        triggeringExamples: ComputedAccessorsOrderRuleExamples.triggeringExamples
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        ComputedAccessorsOrderRuleVisitor(expectedOrder: configuration.order)
    }
}

private final class ComputedAccessorsOrderRuleVisitor: ViolationsSyntaxVisitor {
    enum ViolationKind {
        case `subscript`, property
    }

    private let expectedOrder: ComputedAccessorsOrderConfiguration.Order

    init(expectedOrder: ComputedAccessorsOrderConfiguration.Order) {
        self.expectedOrder = expectedOrder
        super.init(viewMode: .sourceAccurate)
    }

    override func visitPost(_ node: AccessorBlockSyntax) {
        guard let firstAccessor = node.accessors.first,
              let order = node.order,
              order != expectedOrder else {
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

    private func reason(for kind: ComputedAccessorsOrderRuleVisitor.ViolationKind) -> String {
        let kindString = kind == .subscript ? "subscripts" : "properties"
        let orderString: String
        switch expectedOrder {
        case .getSet:
            orderString = "getter and then the setter"
        case .setGet:
            orderString = "setter and then the getter"
        }
        return "Computed \(kindString) should first declare the \(orderString)"
    }
}

private extension AccessorBlockSyntax {
    var order: ComputedAccessorsOrderConfiguration.Order? {
        guard accessors.count == 2, accessors.map(\.body).allSatisfy({ $0 != nil }) else {
            return nil
        }

        let tokens = accessors.map(\.accessorKind.tokenKind)
        if tokens == [.keyword(.get), .keyword(.set)] {
            return .getSet
        }

        if tokens == [.keyword(.set), .keyword(.get)] {
            return .setGet
        }

        return nil
    }
}
