import SwiftSyntax

private let warnDeprecatedOnceImpl: Void = {
    queuedPrintError("""
        The `\(InertDeferRule.description.identifier)` rule is now deprecated and will be completely \
        removed in a future release due to an equivalent warning issued by the Swift compiler.
        """
    )
}()

private func warnDeprecatedOnce() {
    _ = warnDeprecatedOnceImpl
}

struct InertDeferRule: ConfigurationProviderRule, SwiftSyntaxRule, OptInRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "inert_defer",
        name: "Inert Defer",
        description: "If defer is at the end of its parent scope, it will be executed right where it is anyway",
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
            """),
            Example("""
            func f() {
                #if os(macOS)
                defer { print(2) }
                #else
                defer { print(3) }
                #endif
                print(1)
            }
            """, excludeFromDocumentation: true)
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
            """),
            Example("""
            func f(arg: Int) {
                if arg == 1 {
                    ↓defer { print(2) }
                    // a comment
                } else {
                    ↓defer { print(3) }
                }
                print(1)
                #if os(macOS)
                ↓defer { print(4) }
                #else
                ↓defer { print(5) }
                #endif
            }
            """, excludeFromDocumentation: true)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        warnDeprecatedOnce()
        return Visitor(viewMode: .sourceAccurate)
    }
}

private extension InertDeferRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: DeferStmtSyntax) {
            guard node.isLastStatement else {
                return
            }
            if let ifConfigClause = node.parent?.parent?.parent?.as(IfConfigClauseSyntax.self),
               ifConfigClause.parent?.parent?.isLastStatement == false {
                return
            }

            violations.append(node.deferKeyword.positionAfterSkippingLeadingTrivia)
        }
    }
}

private extension SyntaxProtocol {
    var isLastStatement: Bool {
        if let codeBlockItem = parent?.as(CodeBlockItemSyntax.self),
           let codeBlockList = codeBlockItem.parent?.as(CodeBlockItemListSyntax.self) {
            return codeBlockList.last == codeBlockItem
        }
        return false
    }
}
