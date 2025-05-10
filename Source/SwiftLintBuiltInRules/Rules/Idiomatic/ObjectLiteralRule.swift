import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct ObjectLiteralRule: Rule {
    var configuration = ObjectLiteralConfiguration<Self>()

    static let description = RuleDescription(
        identifier: "object_literal",
        name: "Object Literal",
        description: "Prefer object literals over image and color inits",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("let image = #imageLiteral(resourceName: \"image.jpg\")"),
            Example("let color = #colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)"),
            Example("let image = UIImage(named: aVariable)"),
            Example("let image = UIImage(named: \"interpolated \\(variable)\")"),
            Example("let color = UIColor(red: value, green: value, blue: value, alpha: 1)"),
            Example("let image = NSImage(named: aVariable)"),
            Example("let image = NSImage(named: \"interpolated \\(variable)\")"),
            Example("let color = NSColor(red: value, green: value, blue: value, alpha: 1)"),
        ],
        triggeringExamples: ["", ".init"].flatMap { (method: String) -> [Example] in
            ["UI", "NS"].flatMap { (prefix: String) -> [Example] in
                [
                    Example("let image = ↓\(prefix)Image\(method)(named: \"foo\")"),
                    Example("let color = ↓\(prefix)Color\(method)(red: 0.3, green: 0.3, blue: 0.3, alpha: 1)"),
                    // swiftlint:disable:next line_length
                    Example("let color = ↓\(prefix)Color\(method)(red: 100 / 255.0, green: 50 / 255.0, blue: 0, alpha: 1)"),
                    Example("let color = ↓\(prefix)Color\(method)(white: 0.5, alpha: 1)"),
                ]
            }
        }
    )
}

private extension ObjectLiteralRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard configuration.colorLiteral || configuration.imageLiteral else {
                return
            }

            let name = node.calledExpression.trimmedDescription
            if configuration.imageLiteral, isImageNamedInit(node: node, name: name) {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            } else if configuration.colorLiteral, isColorInit(node: node, name: name) {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }

        private func isImageNamedInit(node: FunctionCallExprSyntax, name: String) -> Bool {
            guard inits(forClasses: ["UIImage", "NSImage"]).contains(name),
                  node.arguments.compactMap(\.label?.text) == ["named"],
                  let argument = node.arguments.first?.expression.as(StringLiteralExprSyntax.self),
                  argument.isConstantString else {
                return false
            }

            return true
        }

        private func isColorInit(node: FunctionCallExprSyntax, name: String) -> Bool {
            guard inits(forClasses: ["UIColor", "NSColor"]).contains(name),
                  case let argumentsNames = node.arguments.compactMap(\.label?.text),
                argumentsNames == ["red", "green", "blue", "alpha"] || argumentsNames == ["white", "alpha"] else {
                    return false
            }

            return node.arguments.allSatisfy(\.expression.canBeExpressedAsColorLiteralParams)
        }

        private func inits(forClasses names: [String]) -> [String] {
            names.flatMap { name in
                [
                    name,
                    name + ".init",
                ]
            }
        }
    }
}

private extension StringLiteralExprSyntax {
    var isConstantString: Bool {
        segments.allSatisfy { $0.is(StringSegmentSyntax.self) }
    }
}

private extension ExprSyntax {
    var canBeExpressedAsColorLiteralParams: Bool {
        if self.is(FloatLiteralExprSyntax.self) ||
            self.is(IntegerLiteralExprSyntax.self) ||
            self.is(BinaryOperatorExprSyntax.self) {
            return true
        }

        if let expr = self.as(SequenceExprSyntax.self) {
            return expr.elements.allSatisfy(\.canBeExpressedAsColorLiteralParams)
        }

        return false
    }
}
