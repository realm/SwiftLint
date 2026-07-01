import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct ProhibitedInterfaceBuilderRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "prohibited_interface_builder",
        name: "Prohibited Interface Builder",
        description: "Creating views using Interface Builder should be avoided",
        kind: .lint,
        nonTriggeringExamples: #examples([
            wrapExample("var label: UILabel!"),
            wrapExample("@objc func buttonTapped(_ sender: UIButton) {}"),
        ]),
        triggeringExamples: #examples([
            wrapExample("@IBOutlet ↓var label: UILabel!"),
            wrapExample("@IBAction ↓func buttonTapped(_ sender: UIButton) {}"),
        ])
    )
}

private extension ProhibitedInterfaceBuilderRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: VariableDeclSyntax) {
            if node.isIBOutlet {
                violations.append(node.bindingSpecifier.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            if node.isIBAction {
                violations.append(node.funcKeyword.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}

private func wrapExample(_ text: String) -> Example {
    // No need to capture file and line here, because they are overwritten by the #examples macro.
    Example("""
    class ViewController: UIViewController {
        \(text)
    }
    """)
}
