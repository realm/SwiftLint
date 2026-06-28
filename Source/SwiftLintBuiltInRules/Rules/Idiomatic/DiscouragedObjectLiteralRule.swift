import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct DiscouragedObjectLiteralRule: Rule {
    var configuration = DiscouragedObjectLiteralConfiguration()

    static let description = RuleDescription(
        identifier: "discouraged_object_literal",
        name: "Discouraged Object Literal",
        description: "Prefer initializers over object literals",
        kind: .idiomatic,
        nonTriggeringExamples: #examples([
            "let image = UIImage(named: aVariable)",
            "let image = UIImage(named: \"interpolated \\(variable)\")",
            "let color = UIColor(red: value, green: value, blue: value, alpha: 1)",
            "let image = NSImage(named: aVariable)",
            "let image = NSImage(named: \"interpolated \\(variable)\")",
            "let color = NSColor(red: value, green: value, blue: value, alpha: 1)",
        ]),
        triggeringExamples: #examples([
            "let image = ↓#imageLiteral(resourceName: \"image.jpg\")",
            "let color = ↓#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)",
        ])
    )
}

private extension DiscouragedObjectLiteralRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: MacroExpansionExprSyntax) {
            guard
                case let .identifier(identifierText) = node.macroName.tokenKind,
                ["colorLiteral", "imageLiteral"].contains(identifierText)
            else {
                return
            }

            if !configuration.imageLiteral, identifierText == "imageLiteral" {
                return
            }

            if !configuration.colorLiteral, identifierText == "colorLiteral" {
                return
            }

            violations.append(node.positionAfterSkippingLeadingTrivia)
        }
    }
}
