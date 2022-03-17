import Foundation
import SourceKittenFramework
import SwiftSyntax

public struct IdenticalOperandsRule: ConfigurationProviderRule, OptInRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    private static let operators = ["==", "!=", "===", "!==", ">", ">=", "<", "<="]

    public static let description = RuleDescription(
        identifier: "identical_operands",
        name: "Identical Operands",
        description: "Comparing two identical operands is likely a mistake.",
        kind: .lint,
        nonTriggeringExamples: operators.flatMap { operation in
            [
                Example("1 \(operation) 2"),
                Example("foo \(operation) bar"),
                Example("prefixedFoo \(operation) foo"),
                Example("foo.aProperty \(operation) foo.anotherProperty"),
                Example("self.aProperty \(operation) self.anotherProperty"),
                Example("\"1 \(operation) 1\""),
                Example("self.aProperty \(operation) aProperty"),
                Example("lhs.aProperty \(operation) rhs.aProperty"),
                Example("lhs.identifier \(operation) rhs.identifier"),
                Example("i \(operation) index"),
                Example("$0 \(operation) 0"),
                Example("keyValues?.count ?? 0 \(operation) 0"),
                Example("string \(operation) string.lowercased()"),
                Example("""
                let num: Int? = 0
                _ = num != nil && num \(operation) num?.byteSwapped
                """),
                Example("num \(operation) num!.byteSwapped")
            ]
        } + [
            // swiftlint:disable:next line_length
            Example("func evaluate(_ mode: CommandMode) -> Result<AutoCorrectOptions, CommandantError<CommandantError<()>>>"),
            Example("let array = Array<Array<Int>>()"),
            Example("guard Set(identifiers).count != identifiers.count else { return }"),
            Example(#"expect("foo") == "foo""#),
            Example("type(of: model).cachePrefix == cachePrefix"),
            Example("histogram[156].0 == 0x003B8D96 && histogram[156].1 == 1"),
            Example(#"[Wrapper(type: .three), Wrapper(type: .one)].sorted { "\($0.type)" > "\($1.type)"}"#)
        ],
        triggeringExamples: operators.flatMap { operation in
            [
                Example("↓1 \(operation) 1"),
                Example("↓foo \(operation) foo"),
                Example("↓foo.aProperty \(operation) foo.aProperty"),
                Example("↓self.aProperty \(operation) self.aProperty"),
                Example("↓$0 \(operation) $0"),
                Example("↓a?.b \(operation) a?.b"),
                Example("if (↓elem \(operation) elem) {}"),
                Example("XCTAssertTrue(↓s3 \(operation) s3)"),
                Example("if let tab = tabManager.selectedTab, ↓tab.webView \(operation) tab.webView")
            ]
        } + [
            Example("""
                return ↓lhs.foo == lhs.foo &&
                       lhs.bar == rhs.bar
            """),
            Example("""
                return lhs.foo == rhs.foo &&
                       ↓lhs.bar == lhs.bar
            """)
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        guard let tree = file.syntaxTree else {
            return []
        }
        let rewriter = SequenceExprFoldingRewriter(operatorContext: .makeBuiltinOperatorContext())
        let folded = rewriter.visit(tree)
        let visitor = IdenticalOperandsVisitor()
        visitor.walk(folded)
        return visitor.positions.map { position in
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: ByteCount(position.utf8Offset)))
        }
    }

    private final class IdenticalOperandsVisitor: SyntaxVisitor {
        var positions: [AbsolutePosition] = []

        override func visitPost(_ node: SequenceExprSyntax) {
            guard node.elements.count == 3,
                  let operatorNode = Array(node.elements)[1].as(BinaryOperatorExprSyntax.self),
                  let lhs = node.elements.first,
                  let rhs = node.elements.last,
                  IdenticalOperandsRule.operators.contains(operatorNode.operatorToken.withoutTrivia().text) else {
                return
            }

            if lhs.withoutTrivia().description == rhs.withoutTrivia().description {
                positions.append(lhs.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}
