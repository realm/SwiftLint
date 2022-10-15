import SwiftSyntax

public struct PrivateActionRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "private_action",
        name: "Private Actions",
        description: "IBActions should be private.",
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

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor? {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension PrivateActionRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
            node.modifiers.isPrivateOrFileprivate ? .skipChildren : .visitChildren
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            guard node.isIBAction, !node.isPrivateOrFileprivate else {
                return
            }

            violationPositions.append(node.funcKeyword.positionAfterSkippingLeadingTrivia)
        }
    }
}

private extension FunctionDeclSyntax {
    var isIBAction: Bool {
        guard let attributes = attributes else {
            return false
        }

        return attributes.contains { elem in
            elem.as(AttributeSyntax.self)?.attributeName.tokenKind == .identifier("IBAction")
        }
    }

    var isPrivateOrFileprivate: Bool {
        modifiers.isPrivateOrFileprivate
    }
}

private extension ModifierListSyntax? {
    var isPrivateOrFileprivate: Bool {
        guard let modifiers = self else {
            return false
        }

        return modifiers.contains { elem in
            elem.name.tokenKind == .privateKeyword || elem.name.tokenKind == .fileprivateKeyword
        }
    }
}
