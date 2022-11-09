import SwiftSyntax

struct InertDeferRule: ConfigurationProviderRule, SwiftSyntaxRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "inert_defer",
        name: "Inert Defer",
        description: "If defer is at the end of its parent scope, it will be executed right where it is anyway.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
            func example3() {
                defer { /* deferred code */ }

                print("other code")
            }
            """),
            Example("""
            func example4() {
                if condition {
                    defer { /* deferred code */ }
                    print("other code")
                }
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            func example0() {
                ↓defer { /* deferred code */ }
            }
            """),
            Example("""
            func example1() {
                ↓defer { /* deferred code */ }
                // comment
            }
            """),
            Example("""
            func example2() {
                if condition {
                    ↓defer { /* deferred code */ }
                    // comment
                }
            }
            """)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension InertDeferRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: DeferStmtSyntax) {
            guard let codeBlockItem = node.parent?.as(CodeBlockItemSyntax.self),
                  let codeBlockList = codeBlockItem.parent?.as(CodeBlockItemListSyntax.self),
                  codeBlockList.last == codeBlockItem  else {
                return
            }

            violations.append(node.deferKeyword.positionAfterSkippingLeadingTrivia)
        }
    }
}
