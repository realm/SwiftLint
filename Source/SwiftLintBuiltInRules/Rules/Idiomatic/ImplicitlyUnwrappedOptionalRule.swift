import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct ImplicitlyUnwrappedOptionalRule: Rule {
    var configuration = ImplicitlyUnwrappedOptionalConfiguration()

    static let description = RuleDescription(
        identifier: "implicitly_unwrapped_optional",
        name: "Implicitly Unwrapped Optional",
        description: "Implicitly unwrapped optionals should be avoided when possible",
        kind: .idiomatic,
        nonTriggeringExamples: #examples([
            "@IBOutlet private var label: UILabel!",
            "@IBOutlet var label: UILabel!",
            "@IBOutlet var label: [UILabel!]",
            "if !boolean {}",
            "let int: Int? = 42",
            "let int: Int? = nil",
            """
            class MyClass {
                @IBOutlet
                weak var bar: SomeObject!
            }
            """.configuration(["mode": "all_except_iboutlets"]).excludeFromDocumentation(),
        ]),
        triggeringExamples: #examples([
            "let label: ↓UILabel!",
            "let IBOutlet: ↓UILabel!",
            "let labels: [↓UILabel!]",
            "var ints: [↓Int!] = [42, nil, 42]",
            "let label: ↓IBOutlet!",
            "let int: ↓Int! = 42",
            "let int: ↓Int! = nil",
            "var int: ↓Int! = 42",
            "let collection: AnyCollection<↓Int!>",
            "func foo(int: ↓Int!) {}",
            """
            class MyClass {
                weak var bar: ↓SomeObject!
            }
            """,
        ])
    )
}

private extension ImplicitlyUnwrappedOptionalRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: ImplicitlyUnwrappedOptionalTypeSyntax) {
            violations.append(node.positionAfterSkippingLeadingTrivia)
        }

        override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
            switch configuration.mode {
            case .all:
                return .visitChildren
            case .allExceptIBOutlets:
                return node.isIBOutlet ? .skipChildren : .visitChildren
            case .weakExceptIBOutlets:
                return (node.isIBOutlet || node.weakOrUnownedModifier == nil) ? .skipChildren : .visitChildren
            }
        }
    }
}
