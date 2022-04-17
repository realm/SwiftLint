import SourceKittenFramework
import SwiftSyntax

public struct TuplePatternRule: ConfigurationProviderRule, AutomaticTestableRule {
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
        guard let syntaxTree = file.syntaxTree else {
            return []
        }

        let visitor = TuplePatternVisitor()
        visitor.walk(syntaxTree)
        return visitor.violations(for: self, in: file)
    }
}

private class TuplePatternVisitor: SyntaxVisitor {
    private var positions = [AbsolutePosition]()

    override func visitPost(_ node: PatternBindingSyntax) {
        guard let tuplePattern = node.pattern.as(TuplePatternSyntax.self),
            case let leftSideLabels = tuplePattern.labels,
            !leftSideLabels.compactMap({ $0 }).isEmpty,
            let rightSideLabels = node.initializer?.tupleElementList?.labels,
            leftSideLabels != rightSideLabels else {
            return
        }

        positions.append(node.positionAfterSkippingLeadingTrivia)
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
    var tupleElementList: TupleExprElementListSyntax? {
        if let expr = value.as(TupleExprSyntax.self) {
            return expr.elementList
        }

        return nil
    }
}

private extension TupleExprElementListSyntax {
    var labels: [String?] {
        return map { element in
            element.label?.withoutTrivia().text
        }
    }
}
