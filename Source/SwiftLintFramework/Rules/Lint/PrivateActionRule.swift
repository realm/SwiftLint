import SwiftSyntax

struct PrivateActionRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "private_action",
        name: "Private Actions",
        description: "IBActions should be private",
        kind: .lint,
        nonTriggeringExamples: [
            Example("class Foo {\n\t@IBAction private func barButtonTapped(_ sender: UIButton) {}\n}\n"),
            Example("struct Foo {\n\t@IBAction private func barButtonTapped(_ sender: UIButton) {}\n}\n"),
            Example("class Foo {\n\t@IBAction fileprivate func barButtonTapped(_ sender: UIButton) {}\n}\n"),
            Example("struct Foo {\n\t@IBAction fileprivate func barButtonTapped(_ sender: UIButton) {}\n}\n"),
            Example("private extension Foo {\n\t@IBAction func barButtonTapped(_ sender: UIButton) {}\n}\n"),
            Example("fileprivate extension Foo {\n\t@IBAction func barButtonTapped(_ sender: UIButton) {}\n}\n")
        ],
        triggeringExamples: [
            Example("class Foo {\n\t@IBAction ↓func barButtonTapped(_ sender: UIButton) {}\n}\n"),
            Example("struct Foo {\n\t@IBAction ↓func barButtonTapped(_ sender: UIButton) {}\n}\n"),
            Example("class Foo {\n\t@IBAction public ↓func barButtonTapped(_ sender: UIButton) {}\n}\n"),
            Example("struct Foo {\n\t@IBAction public ↓func barButtonTapped(_ sender: UIButton) {}\n}\n"),
            Example("class Foo {\n\t@IBAction internal ↓func barButtonTapped(_ sender: UIButton) {}\n}\n"),
            Example("struct Foo {\n\t@IBAction internal ↓func barButtonTapped(_ sender: UIButton) {}\n}\n"),
            Example("extension Foo {\n\t@IBAction ↓func barButtonTapped(_ sender: UIButton) {}\n}\n"),
            Example("extension Foo {\n\t@IBAction public ↓func barButtonTapped(_ sender: UIButton) {}\n}\n"),
            Example("extension Foo {\n\t@IBAction internal ↓func barButtonTapped(_ sender: UIButton) {}\n}\n"),
            Example("public extension Foo {\n\t@IBAction ↓func barButtonTapped(_ sender: UIButton) {}\n}\n"),
            Example("internal extension Foo {\n\t@IBAction ↓func barButtonTapped(_ sender: UIButton) {}\n}\n")
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension PrivateActionRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
            node.modifiers.isPrivateOrFileprivate ? .skipChildren : .visitChildren
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            guard node.isIBAction, !node.modifiers.isPrivateOrFileprivate else {
                return
            }

            violations.append(node.funcKeyword.positionAfterSkippingLeadingTrivia)
        }
    }
}
