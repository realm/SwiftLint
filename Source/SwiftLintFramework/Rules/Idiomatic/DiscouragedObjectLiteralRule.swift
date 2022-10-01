import SwiftSyntax

public struct DiscouragedObjectLiteralRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    public var configuration = ObjectLiteralConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "discouraged_object_literal",
        name: "Discouraged Object Literal",
        description: "Prefer initializers over object literals.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("let image = UIImage(named: aVariable)"),
            Example("let image = UIImage(named: \"interpolated \\(variable)\")"),
            Example("let color = UIColor(red: value, green: value, blue: value, alpha: 1)"),
            Example("let image = NSImage(named: aVariable)"),
            Example("let image = NSImage(named: \"interpolated \\(variable)\")"),
            Example("let color = NSColor(red: value, green: value, blue: value, alpha: 1)")
        ],
        triggeringExamples: [
            Example("let image = ↓#imageLiteral(resourceName: \"image.jpg\")"),
            Example("let color = ↓#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)")
        ]
    )

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor? {
        Visitor(configuration: configuration)
    }

    public func makeViolation(file: SwiftLintFile, position: AbsolutePosition) -> StyleViolation {
        StyleViolation(
            ruleDescription: Self.description,
            severity: configuration.severityConfiguration.severity,
            location: Location(file: file, position: position)
        )
    }
}

private extension DiscouragedObjectLiteralRule {
    final class Visitor: SyntaxVisitor, ViolationsSyntaxVisitor {
        private(set) var violationPositions: [AbsolutePosition] = []
        private let configuration: ObjectLiteralConfiguration

        init(configuration: ObjectLiteralConfiguration) {
            self.configuration = configuration
            super.init(viewMode: .sourceAccurate)
        }

        override func visitPost(_ node: ObjectLiteralExprSyntax) {
            if !configuration.imageLiteral && node.identifier.text == "#imageLiteral" {
                return
            }

            if !configuration.colorLiteral && node.identifier.text == "#colorLiteral" {
                return
            }

            violationPositions.append(node.positionAfterSkippingLeadingTrivia)
        }
    }
}
