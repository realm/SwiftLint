import Foundation
import SourceKittenFramework
import SwiftSyntax

private final class FallthroughVisitor: SyntaxVisitor {
    var positions = [AbsolutePosition]()

    override func visit(_ node: FallthroughStmtSyntax) {
        positions.append(node.positionAfterSkippingLeadingTrivia)
    }
}

public struct FallthroughRule: ConfigurationProviderRule, OptInRule, AutomaticTestableRule {

    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "fallthrough",
        name: "Fallthrough",
        description: "Fallthrough should be avoided.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            "switch foo {\n" +
            "case .bar, .bar2, .bar3:\n" +
            "    something()\n" +
            "}"
        ],
        triggeringExamples: [
            "switch foo {\n" +
            "case .bar:\n" +
            "    ↓fallthrough\n" +
            "case .bar2:\n" +
            "    something()\n" +
            "}"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        let url = URL(fileURLWithPath: file.path!)
        let sourceFile = try! SyntaxTreeParser.parse(url)
        let visitor = FallthroughVisitor()
        visitor.visit(sourceFile)
        return visitor.positions.map { position in
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: position.utf8Offset))
        }
    }
}
