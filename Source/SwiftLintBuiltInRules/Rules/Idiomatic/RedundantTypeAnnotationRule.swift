import Foundation
import SwiftSyntax
import SwiftLintCore

struct RedundantTypeAnnotationRule: SwiftSyntaxCorrectableRule, OptInRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor<ConfigurationType> {
        Visitor(configuration: configuration, file: file)
    }

    func makeRewriter(file: SwiftLintFile) -> (some ViolationsSyntaxRewriter)? {
        Rewriter(
            locationConverter: file.locationConverter,
            disabledRegions: disabledRegions(file: file)
        )
    }
}

private extension RedundantTypeAnnotationRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: VariableDeclSyntax) {
            // Only take the last binding into account in case multiple
            // variables are declared on a single line.
            // If this binding has both a type annotation and an initializer
            // it means the type annoation is considered redundant.
            guard let binding = node.bindings.last,
                  binding.typeAnnotation != nil,
                  binding.initializer != nil,
                  !node.attributes.contains(attributeNamed: "IBInspectable")
            else {
                return
            }

            violations.append(node.bindingSpecifier.positionAfterSkippingLeadingTrivia)
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter {
        override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
            guard let lastBinding = node.bindings.last,
                  let typeAnnotation = lastBinding.typeAnnotation,
                  let initializer = lastBinding.initializer
            else {
                return super.visit(node)
            }

            correctionPositions.append(typeAnnotation.positionAfterSkippingLeadingTrivia)

            // Add a leading whitespace to the initializer sequence so there is one
            // between the variable name and the '=' sign
            let initializerWithLeadingWhitespace = initializer
                .with(\.leadingTrivia, Trivia.space)
            // Set the type annotation of the last binding to nil to remove redundancy
            let lastBindingWithoutTypeAnnotation = lastBinding
                .with(\.typeAnnotation, nil)
                .with(\.initializer, initializerWithLeadingWhitespace)

            return super.visit(node.with(
                \.bindings,
                node.bindings.dropLast() + [lastBindingWithoutTypeAnnotation]
            ))
        }
    }
}

extension RedundantTypeAnnotationRule {
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
