import SwiftSyntax

public struct ImplicitGetterRule: ConfigurationProviderRule, SwiftSyntaxRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "implicit_getter",
        name: "Implicit Getter",
        description: "Computed read-only properties and subscripts should avoid using the get keyword.",
        kind: .style,
        nonTriggeringExamples: ImplicitGetterRuleExamples.nonTriggeringExamples,
        triggeringExamples: ImplicitGetterRuleExamples.triggeringExamples
    )

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor? {
        ImplicitGetterRuleVisitor()
    }
}

private final class ImplicitGetterRuleVisitor: SyntaxVisitor, ViolationsSyntaxVisitor {
    private(set) var violationPositions: [AbsolutePosition] = []

    override func visitPost(_ node: AccessorBlockSyntax) {
        guard let getAccessor = node.getAccessor,
              !node.containsSetAccessor,
              getAccessor.asyncKeyword == nil,
              getAccessor.throwsKeyword == nil,
              getAccessor.modifier == nil,
              (getAccessor.attributes == nil || getAccessor.attributes?.isEmpty == true),
              getAccessor.body != nil else {
            return
        }

        violationPositions.append(getAccessor.positionAfterSkippingLeadingTrivia)
    }
}

private extension AccessorBlockSyntax {
    var getAccessor: AccessorDeclSyntax? {
        return accessors.first { accessor in
            accessor.accessorKind.tokenKind == .contextualKeyword("get")
        }
    }

    var containsSetAccessor: Bool {
        return accessors.contains { accessor in
            accessor.accessorKind.tokenKind == .contextualKeyword("set")
        }
    }
}
