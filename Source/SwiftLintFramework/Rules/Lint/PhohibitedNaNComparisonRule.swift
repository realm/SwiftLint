import Foundation
import SourceKittenFramework
#if canImport(SwiftSyntax)
import SwiftSyntax
#endif

public struct PhohibitedNaNComparisonRule: ConfigurationProviderRule, SyntaxRule, OptInRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "prohibited_nan_comparison",
        name: "Prohibited NaN Comparison",
        description: "Use `isNaN` instead of comparing values to the `.nan` constant.",
        kind: .lint,
        minSwiftVersion: .fiveDotOne,
        nonTriggeringExamples: [
            Example("if number.isNaN {}"),
            Example("if foo.nan == 3 {}") // allows using in non-types
        ],
        triggeringExamples: [
            Example("if number == .nan {}"),
            Example("if number + 1 == .nan {}"),
            Example("if number == Float.nan {}"),
            Example("if .nan == number {}"),
            Example("if Double.nan == number {}")
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        #if canImport(SwiftSyntax)
        return validate(file: file, visitor: BinaryOperatorVisitor())
        #else
        return []
        #endif
    }
}

#if canImport(SwiftSyntax)
private class BinaryOperatorVisitor: SyntaxRuleVisitor {
    private var positions = [AbsolutePosition]()
    private let operators: Set = ["==", "!="]

    func visit(_ node: BinaryOperatorExprSyntax) -> SyntaxVisitorContinueKind {
        if operators.contains(node.operatorToken.withoutTrivia().text), let children = node.parent?.children {
            let array = Array(children)
            let before = array[array.index(before: node.indexInParent)]
            let after = array[array.index(after: node.indexInParent)]

            if before.isNaN || after.isNaN {
                positions.append(node.operatorToken.positionAfterSkippingLeadingTrivia)
            }
        }

        return .visitChildren
    }

    func violations(for rule: PhohibitedNaNComparisonRule, in file: SwiftLintFile) -> [StyleViolation] {
        return positions.map { position in
            StyleViolation(ruleDescription: type(of: rule).description,
                           severity: rule.configuration.severity,
                           location: Location(file: file, byteOffset: ByteCount(position.utf8Offset)))
        }
    }
}

private extension Syntax {
    var isNaN: Bool {
        guard let memberExpr = self as? MemberAccessExprSyntax else {
            return false
        }

        let isNaNProperty = memberExpr.name.withoutTrivia().text == "nan"
        return isNaNProperty && (memberExpr.base == nil || memberExpr.base?.referringToType == true)
    }
}

private extension ExprSyntax {
    var referringToType: Bool {
        guard let expr = self as? IdentifierExprSyntax else {
            return false
        }

        return expr.identifier.classifications.map { $0.kind } == [.identifier] &&
            expr.identifier.withoutTrivia().text.isTypeLike
    }
}

private extension String {
    var isTypeLike: Bool {
        guard let firstLetter = unicodeScalars.first else {
            return false
        }

        return CharacterSet.uppercaseLetters.contains(firstLetter)
    }
}
#endif
