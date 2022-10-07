import SwiftSyntax

public struct ProhibitedInterfaceBuilderRule: ConfigurationProviderRule, SwiftSyntaxRule, OptInRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "prohibited_interface_builder",
        name: "Prohibited Interface Builder",
        description: "Creating views using Interface Builder should be avoided.",
        kind: .lint,
        nonTriggeringExamples: [
            wrapExample("var label: UILabel!"),
            wrapExample("@objc func buttonTapped(_ sender: UIButton) {}")
        ],
        triggeringExamples: [
            wrapExample("@IBOutlet ↓var label: UILabel!"),
            wrapExample("@IBAction ↓func buttonTapped(_ sender: UIButton) {}")
        ]
    )

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor? {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension ProhibitedInterfaceBuilderRule {
    final class Visitor: SyntaxVisitor, ViolationsSyntaxVisitor {
        private(set) var violationPositions: [AbsolutePosition] = []

        override func visitPost(_ node: VariableDeclSyntax) {
            if node.isIBOutlet {
                violationPositions.append(node.letOrVarKeyword.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            if node.isIBAction {
                violationPositions.append(node.funcKeyword.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}

private extension VariableDeclSyntax {
    var isIBOutlet: Bool {
        attributes?.contains { attr in
            attr.as(AttributeSyntax.self)?.attributeName.tokenKind == .identifier("IBOutlet")
        } ?? false
    }
}

private extension FunctionDeclSyntax {
    var isIBAction: Bool {
        attributes?.contains { attr in
            attr.as(AttributeSyntax.self)?.attributeName.tokenKind == .identifier("IBAction")
        } ?? false
    }
}

private func wrapExample(_ text: String, file: StaticString = #file, line: UInt = #line) -> Example {
    return Example("""
    class ViewController: UIViewController {
        \(text)
    }
    """, file: file, line: line)
}
