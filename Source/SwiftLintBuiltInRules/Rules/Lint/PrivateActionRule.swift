import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct PrivateActionRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "private_action",
        name: "Private Actions",
        description: "IBActions should be private",
        kind: .lint,
        nonTriggeringExamples: [
            Example("class Foo {\n\t@IBAction private func barButtonTapped(_ sender: UIButton) {}\n}"),
            Example("struct Foo {\n\t@IBAction private func barButtonTapped(_ sender: UIButton) {}\n}"),
            Example("class Foo {\n\t@IBAction fileprivate func barButtonTapped(_ sender: UIButton) {}\n}"),
            Example("struct Foo {\n\t@IBAction fileprivate func barButtonTapped(_ sender: UIButton) {}\n}"),
            Example("private extension Foo {\n\t@IBAction func barButtonTapped(_ sender: UIButton) {}\n}"),
            Example("fileprivate extension Foo {\n\t@IBAction func barButtonTapped(_ sender: UIButton) {}\n}"),
        ],
        triggeringExamples: [
            Example("class Foo {\n\t@IBAction ↓func barButtonTapped(_ sender: UIButton) {}\n}"),
            Example("struct Foo {\n\t@IBAction ↓func barButtonTapped(_ sender: UIButton) {}\n}"),
            Example("class Foo {\n\t@IBAction public ↓func barButtonTapped(_ sender: UIButton) {}\n}"),
            Example("struct Foo {\n\t@IBAction public ↓func barButtonTapped(_ sender: UIButton) {}\n}"),
            Example("class Foo {\n\t@IBAction internal ↓func barButtonTapped(_ sender: UIButton) {}\n}"),
            Example("struct Foo {\n\t@IBAction internal ↓func barButtonTapped(_ sender: UIButton) {}\n}"),
            Example("extension Foo {\n\t@IBAction ↓func barButtonTapped(_ sender: UIButton) {}\n}"),
            Example("extension Foo {\n\t@IBAction public ↓func barButtonTapped(_ sender: UIButton) {}\n}"),
            Example("extension Foo {\n\t@IBAction internal ↓func barButtonTapped(_ sender: UIButton) {}\n}"),
            Example("public extension Foo {\n\t@IBAction ↓func barButtonTapped(_ sender: UIButton) {}\n}"),
            Example("internal extension Foo {\n\t@IBAction ↓func barButtonTapped(_ sender: UIButton) {}\n}"),
        ]
    )
}

private extension PrivateActionRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
            node.modifiers.containsPrivateOrFileprivate() ? .skipChildren : .visitChildren
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            guard node.isIBAction, !node.modifiers.containsPrivateOrFileprivate() else {
                return
            }

            violations.append(node.funcKeyword.positionAfterSkippingLeadingTrivia)
        }
    }
}
