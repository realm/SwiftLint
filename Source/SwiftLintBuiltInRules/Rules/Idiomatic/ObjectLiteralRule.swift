import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct ObjectLiteralRule: Rule {
    var configuration = ObjectLiteralConfiguration<Self>()

    static let description = RuleDescription(
        identifier: "object_literal",
        name: "Object Literal",
        description: "Prefer object literals over image and color inits",
        kind: .idiomatic,
        nonTriggeringExamples: #examples([
            "let image = #imageLiteral(resourceName: \"image.jpg\")",
            "let color = #colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)",
            "let image = UIImage(named: aVariable)",
            "let image = UIImage(named: \"interpolated \\(variable)\")",
            "let color = UIColor(red: value, green: value, blue: value, alpha: 1)",
            "let image = NSImage(named: aVariable)",
            "let image = NSImage(named: \"interpolated \\(variable)\")",
            "let color = NSColor(red: value, green: value, blue: value, alpha: 1)",
        ]),
        triggeringExamples: ["", ".init"].flatMap { (method: String) -> [Example] in
            ["UI", "NS"].flatMap { (prefix: String) -> [Example] in
                #examples([
                    "let image = ↓\(prefix)Image\(method)(named: \"foo\")",
                    "let color = ↓\(prefix)Color\(method)(red: 0.3, green: 0.3, blue: 0.3, alpha: 1)",
                    "let color = ↓\(prefix)Color\(method)(red: 100 / 255.0, green: 50 / 255.0, blue: 0, alpha: 1)",
                    "let color = ↓\(prefix)Color\(method)(white: 0.5, alpha: 1)",
                ])
            }
        }
    )
}

private extension ObjectLiteralRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        // Only `X(...)` and `X.init(...)` can match, so the identifier naming `X` is all that has
        // to be looked at to rule a call out. Every other call skips `trimmedDescription`, which
        // rebuilds the called expression's subtree just to render it as a string.
        private static let imageClasses: Set<String> = ["UIImage", "NSImage"]
        private static let colorClasses: Set<String> = ["UIColor", "NSColor"]
        private static let imageInits = inits(forClasses: imageClasses)
        private static let colorInits = inits(forClasses: colorClasses)

        override func visitPost(_ node: FunctionCallExprSyntax) {
            let checkImage = configuration.imageLiteral
            let checkColor = configuration.colorLiteral
            guard checkImage || checkColor else {
                return
            }
            guard let baseName = node.calledExpression.baseIdentifier else {
                return
            }
            let couldBeImage = checkImage && Self.imageClasses.contains(baseName)
            let couldBeColor = checkColor && Self.colorClasses.contains(baseName)
            guard couldBeImage || couldBeColor else {
                return
            }

            let name = node.calledExpression.trimmedDescription
            if couldBeImage, isImageNamedInit(node: node, name: name) {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            } else if couldBeColor, isColorInit(node: node, name: name) {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }

        private func isImageNamedInit(node: FunctionCallExprSyntax, name: String) -> Bool {
            guard Self.imageInits.contains(name),
                  node.arguments.compactMap(\.label?.text) == ["named"],
                  let argument = node.arguments.first?.expression.as(StringLiteralExprSyntax.self),
                  argument.isConstantString else {
                return false
            }

            return true
        }

        private func isColorInit(node: FunctionCallExprSyntax, name: String) -> Bool {
            guard Self.colorInits.contains(name),
                  case let argumentsNames = node.arguments.compactMap(\.label?.text),
                  argumentsNames == ["red", "green", "blue", "alpha"] || argumentsNames == ["white", "alpha"] else {
                return false
            }

            return node.arguments.allSatisfy(\.expression.canBeExpressedAsColorLiteralParams)
        }

        private static func inits(forClasses names: Set<String>) -> Set<String> {
            Set(names.flatMap { name in
                [
                    name,
                    name + ".init",
                ]
            })
        }
    }
}

private extension StringLiteralExprSyntax {
    var isConstantString: Bool {
        segments.allSatisfy { $0.is(StringSegmentSyntax.self) }
    }
}

private extension ExprSyntax {
    /// The identifier naming the callee for the `X` and `X.init` forms, or `nil` for any other
    /// expression. Deliberately matches more than the rule accepts — `X.other` and `X . init`
    /// resolve to `X` here and are rejected later by the exact name comparison — so that using it
    /// to skip work cannot hide a violation.
    var baseIdentifier: String? {
        if let declReference = `as`(DeclReferenceExprSyntax.self) {
            return declReference.baseName.text
        }
        if let memberAccess = `as`(MemberAccessExprSyntax.self),
           let base = memberAccess.base?.as(DeclReferenceExprSyntax.self) {
            return base.baseName.text
        }
        return nil
    }

    var canBeExpressedAsColorLiteralParams: Bool {
        if `is`(FloatLiteralExprSyntax.self) ||
            `is`(IntegerLiteralExprSyntax.self) ||
            `is`(BinaryOperatorExprSyntax.self) {
            return true
        }

        if let expr = `as`(SequenceExprSyntax.self) {
            return expr.elements.allSatisfy(\.canBeExpressedAsColorLiteralParams)
        }

        return false
    }
}
