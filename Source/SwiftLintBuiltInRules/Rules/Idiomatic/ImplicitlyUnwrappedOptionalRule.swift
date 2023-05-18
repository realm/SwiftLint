import SwiftSyntax

struct ImplicitlyUnwrappedOptionalRule: SwiftSyntaxRule, ConfigurationProviderRule, OptInRule {
    var configuration = ImplicitlyUnwrappedOptionalConfiguration()

    static let description = RuleDescription(
        identifier: "implicitly_unwrapped_optional",
        name: "Implicitly Unwrapped Optional",
        description: "Implicitly unwrapped optionals should be avoided when possible",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("@IBOutlet private var label: UILabel!"),
            Example("@IBOutlet var label: UILabel!"),
            Example("@IBOutlet var label: [UILabel!]"),
            Example("if !boolean {}"),
            Example("let int: Int? = 42"),
            Example("let int: Int? = nil"),
            Example("""
            class MyClass {
                @IBOutlet
                weak var bar: SomeObject!
            }
            """, configuration: ["mode": "all_except_iboutlets"], excludeFromDocumentation: true)
        ],
        triggeringExamples: [
            Example("let label: ↓UILabel!"),
            Example("let IBOutlet: ↓UILabel!"),
            Example("let labels: [↓UILabel!]"),
            Example("var ints: [↓Int!] = [42, nil, 42]"),
            Example("let label: ↓IBOutlet!"),
            Example("let int: ↓Int! = 42"),
            Example("let int: ↓Int! = nil"),
            Example("var int: ↓Int! = 42"),
            Example("let collection: AnyCollection<↓Int!>"),
            Example("func foo(int: ↓Int!) {}"),
            Example("""
            class MyClass {
                weak var bar: ↓SomeObject!
            }
            """)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(mode: configuration.mode)
    }
}

private extension ImplicitlyUnwrappedOptionalRule {
    final class Visitor: ViolationsSyntaxVisitor {
        private let mode: ConfigurationType.ImplicitlyUnwrappedOptionalModeConfiguration

        init(mode: ConfigurationType.ImplicitlyUnwrappedOptionalModeConfiguration) {
            self.mode = mode
            super.init(viewMode: .sourceAccurate)
        }

        override func visitPost(_ node: ImplicitlyUnwrappedOptionalTypeSyntax) {
            violations.append(node.positionAfterSkippingLeadingTrivia)
        }

        override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
            switch mode {
            case .all:
                return .visitChildren
            case .allExceptIBOutlets:
                return node.isIBOutlet ? .skipChildren : .visitChildren
            }
        }
    }
}
