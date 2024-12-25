import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true, optIn: true)
struct StrongIBOutletRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "strong_iboutlet",
        name: "Strong IBOutlet",
        description: "@IBOutlets shouldn't be declared as weak",
        kind: .lint,
        nonTriggeringExamples: [
            wrapExample("@IBOutlet var label: UILabel?"),
            wrapExample("weak var label: UILabel?"),
        ],
        triggeringExamples: [
            wrapExample("@IBOutlet ↓weak var label: UILabel?"),
            wrapExample("@IBOutlet ↓unowned var label: UILabel!"),
            wrapExample("@IBOutlet ↓weak var textField: UITextField?"),
        ],
        corrections: [
            wrapExample("@IBOutlet ↓weak var label: UILabel?"):
                wrapExample("@IBOutlet var label: UILabel?"),
            wrapExample("@IBOutlet ↓unowned var label: UILabel!"):
                wrapExample("@IBOutlet var label: UILabel!"),
            wrapExample("@IBOutlet ↓weak var textField: UITextField?"):
                wrapExample("@IBOutlet var textField: UITextField?"),
        ]
    )
}

private extension StrongIBOutletRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: VariableDeclSyntax) {
            if let violationPosition = node.violationPosition {
                violations.append(violationPosition)
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
            guard let violationPosition = node.violationPosition,
                  let weakOrUnownedModifier = node.weakOrUnownedModifier,
                  case let modifiers = node.modifiers else {
                return super.visit(node)
            }

            let newModifiers = modifiers.filter { $0 != weakOrUnownedModifier }
            let newNode = node.with(\.modifiers, newModifiers)
            correctionPositions.append(violationPosition)
            return super.visit(newNode)
        }
    }
}

private extension VariableDeclSyntax {
    var violationPosition: AbsolutePosition? {
        guard let keyword = weakOrUnownedKeyword, isIBOutlet else {
            return nil
        }

        return keyword.positionAfterSkippingLeadingTrivia
    }

    var weakOrUnownedKeyword: TokenSyntax? {
        weakOrUnownedModifier?.name
    }
}

private func wrapExample(_ text: String, file: StaticString = #filePath, line: UInt = #line) -> Example {
    Example("""
    class ViewController: UIViewController {
        \(text)
    }
    """, file: file, line: line)
}
