import SwiftSyntax

public struct DuplicateImportsRule: ConfigurationProviderRule, SwiftSyntaxRule {
    public var configuration = SeverityConfiguration(.warning)

    // List of all possible import kinds
    static let importKinds = [
        "typealias", "struct", "class",
        "enum", "protocol", "let",
        "var", "func"
    ]

    public init() {}

    public static let description = RuleDescription(
        identifier: "duplicate_imports",
        name: "Duplicate Imports",
        description: "Imports should be unique.",
        kind: .idiomatic,
        nonTriggeringExamples: DuplicateImportsRuleExamples.nonTriggeringExamples,
        triggeringExamples: DuplicateImportsRuleExamples.triggeringExamples,
        corrections: DuplicateImportsRuleExamples.corrections
    )

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension DuplicateImportsRule {
    final class Visitor: ViolationsSyntaxVisitor {
        private var imported: Set<String> = []
        override func visitPost(_ node: ImportDeclSyntax) {
            let ifConfigCondition = node.nearestIfConfigClause()?.condition?.description
            let pathDescription = [ifConfigCondition, node.path.withoutTrivia().description]
                .compactMap { $0 }
                .joined(separator: "/")
            if imported.contains(pathDescription) {
                violations.append(node.importTok.positionAfterSkippingLeadingTrivia)
            } else {
                imported.insert(pathDescription)
            }
        }
    }
}

private extension SyntaxProtocol {
    func nearestIfConfigClause() -> IfConfigClauseSyntax? {
        guard let parent = parent else {
            return nil
        }

        return parent.as(IfConfigClauseSyntax.self) ?? parent.nearestIfConfigClause()
    }
}
