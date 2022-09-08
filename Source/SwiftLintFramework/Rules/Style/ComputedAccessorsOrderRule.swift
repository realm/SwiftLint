import SwiftSyntax

public struct ComputedAccessorsOrderRule: ConfigurationProviderRule, SourceKitFreeRule {
    public var configuration = ComputedAccessorsOrderRuleConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "computed_accessors_order",
        name: "Computed Accessors Order",
        description: "Getter and setters in computed properties and subscripts should be in a consistent order.",
        kind: .style,
        nonTriggeringExamples: ComputedAccessorsOrderRuleExamples.nonTriggeringExamples,
        triggeringExamples: ComputedAccessorsOrderRuleExamples.triggeringExamples
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        ComputedAccessorsOrderRuleVisitor(expectedOrder: configuration.order)
            .walk(file: file, handler: \.violationPositions)
            .sorted { $0.position < $1.position }
            .map { violation in
                StyleViolation(
                    ruleDescription: Self.description,
                    severity: configuration.severityConfiguration.severity,
                    location: Location(file: file, position: violation.position),
                    reason: reason(for: violation.kind)
                )
            }
    }

    private func reason(for kind: ComputedAccessorsOrderRuleVisitor.ViolationKind) -> String {
        let kindString = kind == .subscript ? "subscripts" : "properties"
        let orderString: String
        switch configuration.order {
        case .getSet:
            orderString = "getter and then the setter"
        case .setGet:
            orderString = "setter and then the getter"
        }
        return "Computed \(kindString) should declare first the \(orderString)."
    }
}

private final class ComputedAccessorsOrderRuleVisitor: SyntaxVisitor {
    enum ViolationKind {
        case `subscript`, property
    }

    private(set) var violationPositions: [(position: AbsolutePosition, kind: ViolationKind)] = []
    private let expectedOrder: ComputedAccessorsOrderRuleConfiguration.Order

    init(expectedOrder: ComputedAccessorsOrderRuleConfiguration.Order) {
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
        violationPositions.append((firstAccessor.positionAfterSkippingLeadingTrivia, kind))
    }
}

private extension AccessorBlockSyntax {
    var order: ComputedAccessorsOrderRuleConfiguration.Order? {
        guard accessors.count == 2, accessors.map(\.body).allSatisfy({ $0 != nil }) else {
            return nil
        }

        let tokens = accessors.map(\.accessorKind.tokenKind)
        if tokens == [.contextualKeyword("get"), .contextualKeyword("set")] {
            return .getSet
        }

        if tokens == [.contextualKeyword("set"), .contextualKeyword("get")] {
            return .setGet
        }

        return nil
    }
}
