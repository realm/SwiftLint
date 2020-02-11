import Foundation
import SourceKittenFramework
#if canImport(SwiftSyntax)
import SwiftSyntax
#endif

public struct OperatorUsageWhitespaceRule: OptInRule, SyntaxRule, CorrectableRule, ConfigurationProviderRule,
                                           AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "operator_usage_whitespace",
        name: "Operator Usage Whitespace",
        description: "Operators should be surrounded by a single whitespace " +
                     "when they are being used.",
        kind: .style,
        nonTriggeringExamples: [
            Example("let foo = 1 + 2\n"),
            Example("let foo = 1 > 2\n"),
            Example("let foo = !false\n"),
            Example("let foo: Int?\n"),
            Example("let foo: Array<String>\n"),
            Example("let model = CustomView<Container<Button>, NSAttributedString>()\n"),
            Example("let foo: [String]\n"),
            Example("let foo = 1 + \n  2\n"),
            Example("let range = 1...3\n"),
            Example("let range = 1 ... 3\n"),
            Example("let range = 1..<3\n"),
            Example("#if swift(>=3.0)\n    foo()\n#endif\n"),
            Example("array.removeAtIndex(-200)\n"),
            Example("let name = \"image-1\"\n"),
            Example("button.setImage(#imageLiteral(resourceName: \"image-1\"), for: .normal)\n"),
            Example("let doubleValue = -9e-11\n"),
            Example("let foo = GenericType<(UIViewController) -> Void>()\n"),
            Example("let foo = Foo<Bar<T>, Baz>()\n"),
            Example("let foo = SignalProducer<Signal<Value, Error>, Error>([ self.signal, next ]).flatten(.concat)\n"),
            Example("""
            let foo = Foo<A,
                          B>(param: bar)
            """),
            Example("""
            func success(for item: Item) {
                item.successHandler??()
            }
            """)
        ],
        triggeringExamples: [
            Example("let foo = 1↓+2\n"),
            Example("let foo = 1↓   + 2\n"),
            Example("let foo = 1↓   +    2\n"),
            Example("let foo = 1↓ +    2\n"),
            Example("let foo↓=1↓+2\n"),
            Example("let foo↓=1 + 2\n"),
            Example("let foo↓=bar\n"),
            Example("let range = 1↓ ..<  3\n"),
            Example("let foo = bar↓   ?? 0\n"),
            Example("let foo = bar↓ !=  0\n"),
            Example("let foo = bar↓ !==  bar2\n"),
            Example("let v8 = Int8(1)↓  << 6\n"),
            Example("let v8 = 1↓ <<  (6)\n"),
            Example("let v8 = 1↓ <<  (6)\n let foo = 1 > 2\n")
        ],
        corrections: [:]
//            Example("let foo = 1↓+2\n"): Example("let foo = 1 + 2\n"),
//            Example("let foo = 1↓   + 2\n"): Example("let foo = 1 + 2\n"),
//            Example("let foo = 1↓   +    2\n"): Example("let foo = 1 + 2\n"),
//            Example("let foo = 1↓ +    2\n"): Example("let foo = 1 + 2\n"),
//            Example("let foo↓=1↓+2\n"): Example("let foo = 1 + 2\n"),
//            Example("let foo↓=1 + 2\n"): Example("let foo = 1 + 2\n"),
//            Example("let foo↓=bar\n"): Example("let foo = bar\n"),
//            Example("let range = 1↓ ..<  3\n"): Example("let range = 1..<3\n"),
//            Example("let foo = bar↓   ?? 0\n"): Example("let foo = bar ?? 0\n"),
//            Example("let foo = bar↓??0\n"): Example("let foo = bar ?? 0\n"),
//            Example("let foo = bar↓ !=  0\n"): Example("let foo = bar != 0\n"),
//            Example("let foo = bar↓ !==  bar2\n"): Example("let foo = bar !== bar2\n"),
//            Example("let v8 = Int8(1)↓  << 6\n"): Example("let v8 = Int8(1) << 6\n"),
//            Example("let v8 = 1↓ <<  (6)\n"): Example("let v8 = 1 << (6)\n"),
//            Example("let v8 = 1↓ <<  (6)\n let foo = 1 > 2\n"): Example("let v8 = 1 << (6)\n let foo = 1 > 2\n")
//        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        #if canImport(SwiftSyntax)
        return validate(file: file, visitor: OperatorVisitor())
        #else
        return []
        #endif
    }

    private func violationRanges(file: SwiftLintFile) -> [(NSRange, String)] {
        return []
    }

    public func correct(file: SwiftLintFile) -> [Correction] {
        let violatingRanges = violationRanges(file: file).filter { range, _ in
            return !file.ruleEnabled(violatingRanges: [range], for: self).isEmpty
        }

        var correctedContents = file.contents
        var adjustedLocations = [Int]()

        for (violatingRange, correction) in violatingRanges.reversed() {
            if let indexRange = correctedContents.nsrangeToIndexRange(violatingRange) {
                correctedContents = correctedContents
                    .replacingCharacters(in: indexRange, with: correction)
                adjustedLocations.insert(violatingRange.location, at: 0)
            }
        }

        file.write(correctedContents)

        return adjustedLocations.map {
            Correction(ruleDescription: type(of: self).description,
                       location: Location(file: file, characterOffset: $0))
        }
    }
}

#if canImport(SwiftSyntax)
private class OperatorVisitor: SyntaxRuleVisitor {
    private var positions = [AbsolutePosition]()

    func visit(_ node: BinaryOperatorExprSyntax) -> SyntaxVisitorContinueKind {
        if let previousToken = node.operatorToken.previousToken,
            previousToken.trailingTrivia != .spaces(1) ||
            node.operatorToken.trailingTrivia != .spaces(1) {


            let operatorText = node.operatorToken.withoutTrivia().text
            let isRangeOperator = operatorText == "..." || operatorText == "..<"
            let shouldIgnore = isRangeOperator && previousToken.trailingTrivia.isEmpty &&
                node.operatorToken.trailingTrivia.isEmpty

            if !shouldIgnore {
                positions.append(previousToken.endPositionBeforeTrailingTrivia)
            }
        }

        return .visitChildren
    }

    func visit(_ node: InitializerClauseSyntax) -> SyntaxVisitorContinueKind {
        if let previousToken = node.equal.previousToken,
            previousToken.trailingTrivia != .spaces(1) ||
            node.equal.trailingTrivia != .spaces(1) {
            positions.append(previousToken.endPositionBeforeTrailingTrivia)
        }

        return .visitChildren
    }

    func violations(for rule: OperatorUsageWhitespaceRule, in file: SwiftLintFile) -> [StyleViolation] {
        return positions.map { position in
            StyleViolation(ruleDescription: type(of: rule).description,
                           severity: rule.configuration.severity,
                           location: Location(file: file, byteOffset: ByteCount(position.utf8Offset)))
        }
    }
}
#endif
