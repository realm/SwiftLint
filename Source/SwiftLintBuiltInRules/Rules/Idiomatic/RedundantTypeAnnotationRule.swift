import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule
struct RedundantTypeAnnotationRule: OptInRule, SwiftSyntaxCorrectableRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "redundant_type_annotation",
        name: "Redundant Type Annotation",
        description: "Variables should not have redundant type annotation",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("var url = URL()"),
            Example("var url: CustomStringConvertible = URL()"),
            Example("@IBInspectable var color: UIColor = UIColor.white"),
            Example("""
            enum Direction {
                case up
                case down
            }

            var direction: Direction = .up
            """),
            Example("""
            enum Direction {
                case up
                case down
            }

            var direction = Direction.up
            """)
        ],
        triggeringExamples: [
            Example("var url↓:URL=URL()"),
            Example("var url↓:URL = URL(string: \"\")"),
            Example("var url↓: URL = URL()"),
            Example("let url↓: URL = URL()"),
            Example("lazy var url↓: URL = URL()"),
            Example("let alphanumerics↓: CharacterSet = CharacterSet.alphanumerics"),
            Example("""
            class ViewController: UIViewController {
              func someMethod() {
                let myVar↓: Int = Int(5)
              }
            }
            """),
            Example("var isEnabled↓: Bool = true"),
            Example("""
            enum Direction {
                case up
                case down
            }

            var direction↓: Direction = Direction.up
            """)
        ],
        corrections: [
            Example("var url↓: URL = URL()"): Example("var url = URL()"),
            Example("let url↓: URL = URL()"): Example("let url = URL()"),
            Example("let alphanumerics↓: CharacterSet = CharacterSet.alphanumerics"):
                Example("let alphanumerics = CharacterSet.alphanumerics"),
            Example("""
            class ViewController: UIViewController {
              func someMethod() {
                let myVar↓: Int = Int(5)
              }
            }
            """):
            Example("""
            class ViewController: UIViewController {
              func someMethod() {
                let myVar = Int(5)
              }
            }
            """)
        ]
    )
}

private extension RedundantTypeAnnotationRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: VariableDeclSyntax) {
            if node.attributes.contains(attributeNamed: "IBInspectable") {
                return
            }
            for binding in node.bindings {
                if let type = binding.typeAnnotation,
                   let typeName = type.type.as(IdentifierTypeSyntax.self)?.name.text,
                   let expr = binding.initializer?.value,
                   typeName == extractPrependingType(from: expr) || isBooleanInit(assignee: typeName, init: expr) {
                    violations.append(type.colon.positionAfterSkippingLeadingTrivia)
                    violationCorrections.append(ViolationCorrection(
                        start: type.colon.positionAfterSkippingLeadingTrivia,
                        end: type.endPositionBeforeTrailingTrivia,
                        replacement: ""
                    ))
                }
            }
        }

        private func extractPrependingType(from expr: ExprSyntax) -> String? {
            if let calledExpr = expr.as(FunctionCallExprSyntax.self)?.calledExpression {
                if let callee = calledExpr.as(DeclReferenceExprSyntax.self) {
                    return callee.baseName.text
                }
                return calledExpr.memberAccessBaseName
            }
            return expr.memberAccessBaseName
        }

        private func isBooleanInit(assignee: String, init expr: ExprSyntax) -> Bool {
            assignee == "Bool" && expr.is(BooleanLiteralExprSyntax.self)
        }
    }
}

private extension ExprSyntax {
    var memberAccessBaseName: String? {
        `as`(MemberAccessExprSyntax.self)?.base?.as(DeclReferenceExprSyntax.self)?.baseName.text
    }
}
