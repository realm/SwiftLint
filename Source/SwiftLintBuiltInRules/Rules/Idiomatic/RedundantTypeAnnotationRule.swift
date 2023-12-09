import Foundation
import SwiftLintCore
import SwiftSyntax

struct RedundantTypeAnnotationRule: SwiftSyntaxCorrectableRule, OptInRule {
    var configuration = RedundantTypeAnnotationConfiguration()

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor<ConfigurationType> {
        Visitor(configuration: configuration, file: file)
    }

    func makeRewriter(file: SwiftLintFile) -> (some ViolationsSyntaxRewriter)? {
        Rewriter(
            configuration: configuration,
            locationConverter: file.locationConverter,
            disabledRegions: disabledRegions(file: file)
        )
    }
}

private extension RedundantTypeAnnotationRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: VariableDeclSyntax) {
            guard node.isViolation(for: configuration) else {
                return
            }

            violations.append(node.bindingSpecifier.positionAfterSkippingLeadingTrivia)
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter {
        private let configuration: RedundantTypeAnnotationConfiguration

        init(configuration: RedundantTypeAnnotationConfiguration, locationConverter: SourceLocationConverter, disabledRegions: [SourceRange]) {
            self.configuration = configuration

            super.init(locationConverter: locationConverter, disabledRegions: disabledRegions)
        }

        override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
            guard node.isViolation(for: configuration),
                  let lastBinding = node.bindings.last,
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

private extension VariableDeclSyntax {
    func isViolation(for configuration: RedundantTypeAnnotationConfiguration) -> Bool {
        // Checks if none of the attributes flagged as ignored in the configuration
        // are set for this declaration
        let doesNotContainIgnoredAttributes = configuration.ignoredAnnotations.allSatisfy {
            !self.attributes.contains(attributeNamed: $0)
        }

        // Only take the last binding into account in case multiple
        // variables are declared on a single line.
        // If this binding has both a type annotation and an initializer
        // it means the type annoation is considered redundant.
        guard let binding = bindings.last,
              binding.typeAnnotation != nil,
              binding.initializer != nil,
              doesNotContainIgnoredAttributes
        else {
            return false
        }

        return true
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
