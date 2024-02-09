import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true)
struct RedundantTypeAnnotationRule: OptInRule {
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
            """),
            Example("let values↓: [Int] = [Int]()"),
            Example(#"static let version↓: AnnouncementStore.Attribute = AnnouncementStore.Attribute("Version")"#)
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
            """),
            Example("let values↓: [Int] = [Int]()"): Example("let values = [Int]()"),
            Example(#"static let version↓: AnnouncementStore.Attribute = AnnouncementStore.Attribute("Version")"#):
                Example(#"static let version = AnnouncementStore.Attribute("Version")"#)
        ]
    )
}

private extension RedundantTypeAnnotationRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: VariableDeclSyntax) {
            if node.isIBInspectable {
                return
            }
            for binding in node.bindings {
                if let typeAnnotation = binding.typeAnnotation, binding.hasViolation {
                    violations.append(typeAnnotation.colon.positionAfterSkippingLeadingTrivia)
                }
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter {
        override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
            if node.isIBInspectable {
                return super.visit(node)
            }

            var modifiedBindings = [PatternBindingSyntax]()
            var hasViolation = false

            for binding in node.bindings {
                guard let typeAnnotation = binding.typeAnnotation, binding.hasViolation else {
                    modifiedBindings.append(binding)
                    continue
                }

                hasViolation = true
                correctionPositions.append(typeAnnotation.colon.positionAfterSkippingLeadingTrivia)

                let updatedInitializer = binding.initializer?.with(\.leadingTrivia, typeAnnotation.trailingTrivia)
                modifiedBindings.append(
                    binding
                        .with(\.typeAnnotation, nil)
                        .with(\.initializer, updatedInitializer)
                )
            }
            return super.visit(hasViolation ? node.with(\.bindings, PatternBindingListSyntax(modifiedBindings)) : node)
        }
    }
}

private extension PatternBindingSyntax {
    var hasViolation: Bool {
        guard let typeAnnotation, let initializer = initializer?.value else {
            return false
        }
        if let function = initializer.as(FunctionCallExprSyntax.self) {
            return typeAnnotation.type.trimmed.description == function.calledExpression.trimmed.description
        } else if let baseExpr = initializer.as(MemberAccessExprSyntax.self)?.base {
            return typeAnnotation.type.trimmed.description == baseExpr.trimmed.description
        } else if typeAnnotation.type.as(IdentifierTypeSyntax.self)?.name.text == "Bool" {
            return initializer.is(BooleanLiteralExprSyntax.self)
        }
        return false
    }
}

private extension VariableDeclSyntax {
    var isIBInspectable: Bool {
        attributes.contains { $0.as(AttributeSyntax.self)?.attributeNameText == "IBInspectable" }
    }
}
