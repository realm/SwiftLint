import SwiftSyntax

struct ObjectLiteralRule: SwiftSyntaxRule, ConfigurationProviderRule, OptInRule {
    var configuration = ObjectLiteralConfiguration()

    init() {}

    static let description = RuleDescription(
        identifier: "object_literal",
        name: "Object Literal",
        description: "Prefer object literals over image and color inits.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("let image = #imageLiteral(resourceName: \"image.jpg\")"),
            Example("let color = #colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)"),
            Example("let image = UIImage(named: aVariable)"),
            Example("let image = UIImage(named: \"interpolated \\(variable)\")"),
            Example("let color = UIColor(red: value, green: value, blue: value, alpha: 1)"),
            Example("let image = NSImage(named: aVariable)"),
            Example("let image = NSImage(named: \"interpolated \\(variable)\")"),
            Example("let color = NSColor(red: value, green: value, blue: value, alpha: 1)")
        ],
        triggeringExamples: ["", ".init"].flatMap { (method: String) -> [Example] in
            ["UI", "NS"].flatMap { (prefix: String) -> [Example] in
                [
                    Example("let image = ↓\(prefix)Image\(method)(named: \"foo\")"),
                    Example("let color = ↓\(prefix)Color\(method)(red: 0.3, green: 0.3, blue: 0.3, alpha: 1)"),
                    // swiftlint:disable:next line_length
                    Example("let color = ↓\(prefix)Color\(method)(red: 100 / 255.0, green: 50 / 255.0, blue: 0, alpha: 1)"),
                    Example("let color = ↓\(prefix)Color\(method)(white: 0.5, alpha: 1)")
                ]
            }
        }
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(validateImageLiteral: configuration.imageLiteral, validateColorLiteral: configuration.colorLiteral)
    }
}

private extension ObjectLiteralRule {
    final class Visitor: ViolationsSyntaxVisitor {
        private let validateImageLiteral: Bool
        private let validateColorLiteral: Bool

        init(validateImageLiteral: Bool, validateColorLiteral: Bool) {
            self.validateImageLiteral = validateImageLiteral
            self.validateColorLiteral = validateColorLiteral
            super.init(viewMode: .sourceAccurate)
        }

        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard validateColorLiteral || validateImageLiteral else {
                return
            }

            let name = node.calledExpression.withoutTrivia().description
            if validateImageLiteral, isImageNamedInit(node: node, name: name) {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            } else if validateColorLiteral, isColorInit(node: node, name: name) {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }

        private func isImageNamedInit(node: FunctionCallExprSyntax, name: String) -> Bool {
            guard inits(forClasses: ["UIImage", "NSImage"]).contains(name),
                  node.argumentList.compactMap(\.label?.text) == ["named"],
                  let argument = node.argumentList.first?.expression.as(StringLiteralExprSyntax.self),
                  argument.isConstantString else {
                return false
            }

            return true
        }

        private func isColorInit(node: FunctionCallExprSyntax, name: String) -> Bool {
            guard inits(forClasses: ["UIColor", "NSColor"]).contains(name),
                case let argumentsNames = node.argumentList.compactMap(\.label?.text),
                argumentsNames == ["red", "green", "blue", "alpha"] || argumentsNames == ["white", "alpha"] else {
                    return false
            }

            return node.argumentList.allSatisfy { elem in
                elem.expression.canBeExpressedAsColorLiteralParams
            }
        }

        private func inits(forClasses names: [String]) -> [String] {
            return names.flatMap { name in
                [
                    name,
                    name + ".init"
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
