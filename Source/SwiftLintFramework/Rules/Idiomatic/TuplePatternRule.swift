import SourceKittenFramework
#if canImport(SwiftSyntax)
import SwiftSyntax
#endif

public struct TuplePatternRule: ConfigurationProviderRule, SyntaxRule, OptInRule,
                                AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "tuple_pattern",
        name: "Tuple Pattern",
        description: "Assigning variables through a tuple pattern is only permitted if the left-hand side of the " +
                     "assignment is unlabeled.",
        kind: .idiomatic,
        minSwiftVersion: .fiveDotOne,
        nonTriggeringExamples: [
            Example("let (a, b) = (y: 4, x: 5.0)"),
            Example("let (a, b) = (4, 5.0)"),
            Example("let (a, b) = (a: 4, b: 5.0)"),
            Example("let (a, b) = tuple")
        ],
        triggeringExamples: [
            Example("let ↓(x: a, y: b) = (y: 4, x: 5.0)"),
            Example("let ↓(x: Int, y: Double) = (y: 4, x: 5.0)"),
            Example("let ↓(x: Int, y: Double) = (y: 4, x: 5.0)")
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        #if canImport(SwiftSyntax)
        return validate(file: file, visitor: PatternBindingVisitor())
        #else
        return []
        #endif
    }
}

#if canImport(SwiftSyntax)
private class PatternBindingVisitor: SyntaxRuleVisitor {
    private var positions = [AbsolutePosition]()

    func visit(_ node: PatternBindingSyntax) -> SyntaxVisitorContinueKind {
        if let tuplePattern = node.pattern as? TuplePatternSyntax,
            case let leftSideLabels = tuplePattern.labels,
            !leftSideLabels.compactMap({ $0 }).isEmpty,
            let rightSideLabels = node.initializer?.tupleElementList?.labels,
            leftSideLabels != rightSideLabels {
            positions.append(node.positionAfterSkippingLeadingTrivia)
        }
        return .visitChildren
    }

    func violations(for rule: TuplePatternRule, in file: SwiftLintFile) -> [StyleViolation] {
        return positions.map { position in
            StyleViolation(ruleDescription: type(of: rule).description,
                           severity: rule.configuration.severity,
                           location: Location(file: file, byteOffset: ByteCount(position.utf8Offset)))
        }
    }
}

private extension TuplePatternSyntax {
    var labels: [String?] {
        return elements.map { element in
            element.labelName?.withoutTrivia().text
        }
    }
}

private extension InitializerClauseSyntax {
    var tupleElementList: TupleElementListSyntax? {
        if let expr = value as? TupleExprSyntax {
            return expr.elementList
        }

        return nil
    }
}

private extension TupleElementListSyntax {
    var labels: [String?] {
        return map { element in
            element.label?.withoutTrivia().text
        }
    }
}
#endif
