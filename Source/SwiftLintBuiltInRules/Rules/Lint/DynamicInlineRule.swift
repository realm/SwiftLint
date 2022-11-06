import SwiftSyntax

struct DynamicInlineRule: SwiftSyntaxRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.error)

    init() {}

    static let description = RuleDescription(
        identifier: "dynamic_inline",
        name: "Dynamic Inline",
        description: "Avoid using 'dynamic' and '@inline(__always)' together",
        kind: .lint,
        nonTriggeringExamples: [
            Example("class C {\ndynamic func f() {}}"),
            Example("class C {\n@inline(__always) func f() {}}"),
            Example("class C {\n@inline(never) dynamic func f() {}}")
        ],
        triggeringExamples: [
            Example("class C {\n@inline(__always) dynamic ↓func f() {}\n}"),
            Example("class C {\n@inline(__always) public dynamic ↓func f() {}\n}"),
            Example("class C {\n@inline(__always) dynamic internal ↓func f() {}\n}"),
            Example("class C {\n@inline(__always)\ndynamic ↓func f() {}\n}"),
            Example("class C {\n@inline(__always)\ndynamic\n↓func f() {}\n}")
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension DynamicInlineRule {
    private final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: FunctionDeclSyntax) {
            guard let modifiers = node.modifiers,
                  let attributes = node.attributes,
                  modifiers.contains(where: { $0.name.text == "dynamic" }),
                  attributes.contains(where: { $0.as(AttributeSyntax.self)?.isInlineAlways == true })
            else {
                return
            }

            violations.append(node.funcKeyword.positionAfterSkippingLeadingTrivia)
        }
    }
}

private extension AttributeSyntax {
    var isInlineAlways: Bool {
        attributeName.text == "inline" &&
            argument?.firstToken?.tokenKind == .identifier("__always")
    }
}
