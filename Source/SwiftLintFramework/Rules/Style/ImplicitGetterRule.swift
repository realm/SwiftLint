import SwiftSyntax

public struct ImplicitGetterRule: ConfigurationProviderRule, SourceKitFreeRule {
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

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        ImplicitGetterRuleVisitor(viewMode: .sourceAccurate)
            .walk(file: file, handler: \.violationPositions)
            .sorted { $0.position < $1.position }
            .map { violation in
                StyleViolation(
                    ruleDescription: Self.description,
                    severity: configuration.severity,
                    location: Location(file: file, position: violation.position),
                    reason: violation.kind.violationDescription
                )
            }
    }
}

private final class ImplicitGetterRuleVisitor: SyntaxVisitor {
    enum ViolationKind {
        case `subscript`, property

        var violationDescription: String {
            switch self {
            case .subscript:
                return "Computed read-only subscripts should avoid using the get keyword."
            case .property:
                return "Computed read-only properties should avoid using the get keyword."
            }
        }
    }
    private(set) var violationPositions: [(position: AbsolutePosition, kind: ViolationKind)] = []

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

        let kind: ViolationKind = node.parent?.as(SubscriptDeclSyntax.self) == nil ? .property : .subscript
        violationPositions.append((getAccessor.positionAfterSkippingLeadingTrivia, kind))
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
