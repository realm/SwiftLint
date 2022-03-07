import SourceKittenFramework
import SwiftSyntax

private let warnSyntaxParserFailureOnceImpl: Void = {
    queuedPrintError("The force_cast rule is disabled because the Swift Syntax tree could not be parsed")
}()

private func warnSyntaxParserFailureOnce() {
    _ = warnSyntaxParserFailureOnceImpl
}

public struct ForceCastRule: ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.error)

    public init() {}

    public static let description = RuleDescription(
        identifier: "force_cast",
        name: "Force Cast",
        description: "Force casts should be avoided.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("NSNumber() as? Int\n")
        ],
        triggeringExamples: [ Example("NSNumber() ↓as! Int\n") ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        guard let tree = try? SyntaxParser.parse(source: file.contents) else {
            warnSyntaxParserFailureOnce()
            return []
        }
        let visitor = ForceCastRuleVisitor()
        visitor.walk(tree)
        return visitor.positions.map { position in
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: ByteCount(position.utf8Offset)))
        }
    }
}

private final class ForceCastRuleVisitor: SyntaxVisitor {
    var positions: [AbsolutePosition] = []

    override func visitPost(_ node: AsExprSyntax) {
        if node.questionOrExclamationMark?.tokenKind == .exclamationMark {
            positions.append(node.asTok.positionAfterSkippingLeadingTrivia)
        }
    }
}
