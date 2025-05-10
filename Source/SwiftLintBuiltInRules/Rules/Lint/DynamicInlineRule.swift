import SwiftSyntax

@SwiftSyntaxRule
struct DynamicInlineRule: Rule {
    var configuration = SeverityConfiguration<Self>(.error)

    static let description = RuleDescription(
        identifier: "dynamic_inline",
        name: "Dynamic Inline",
        description: "Avoid using 'dynamic' and '@inline(__always)' together",
        kind: .lint,
        nonTriggeringExamples: [
            Example("class C {\ndynamic func f() {}}"),
            Example("class C {\n@inline(__always) func f() {}}"),
            Example("class C {\n@inline(never) dynamic func f() {}}"),
        ],
        triggeringExamples: [
            Example("class C {\n@inline(__always) dynamic ↓func f() {}\n}"),
            Example("class C {\n@inline(__always) public dynamic ↓func f() {}\n}"),
            Example("class C {\n@inline(__always) dynamic internal ↓func f() {}\n}"),
            Example("class C {\n@inline(__always)\ndynamic ↓func f() {}\n}"),
            Example("class C {\n@inline(__always)\ndynamic\n↓func f() {}\n}"),
        ]
    )
}

private extension DynamicInlineRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionDeclSyntax) {
            if node.modifiers.contains(where: { $0.name.text == "dynamic" }),
               node.attributes.contains(where: { $0.as(AttributeSyntax.self)?.isInlineAlways == true }) {
                violations.append(node.funcKeyword.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}

private extension AttributeSyntax {
    var isInlineAlways: Bool {
        attributeNameText == "inline" &&
        arguments?.firstToken(viewMode: .sourceAccurate)?.tokenKind == .identifier("__always")
    }
}
