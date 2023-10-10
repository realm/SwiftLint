import SwiftSyntax

// TODO: [12/23/2024] Remove deprecation warning after ~2 years.
private let warnDeprecatedOnceImpl: Void = {
    Issue.ruleDeprecated(ruleID: InertDeferRule.description.identifier).print()
}()

private func warnDeprecatedOnce() {
    _ = warnDeprecatedOnceImpl
}

struct InertDeferRule: SwiftSyntaxRule, OptInRule {
    var configuration = SeverityConfiguration<Self>(.warning)

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

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor<ConfigurationType> {
        warnDeprecatedOnce()
        return Visitor(configuration: configuration, locationConverter: file.locationConverter)
    }
}

private extension InertDeferRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
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
