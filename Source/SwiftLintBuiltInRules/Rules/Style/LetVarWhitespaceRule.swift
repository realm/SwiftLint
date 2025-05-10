import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct LetVarWhitespaceRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "let_var_whitespace",
        name: "Variable Declaration Whitespace",
        description: "Variable declarations should be separated from other statements by a blank line",
        kind: .style,
        nonTriggeringExamples: [
            Example("""
                let a = 0
                var x = 1

                var y = 2
                """),
            Example("""
                let a = 5

                var x = 1
                """),
            Example("""
                var a = 0
                """),
            Example("""
                let a = 1 +
                    2
                let b = 5
                """),
            Example("""
                var x: Int {
                    return 0
                }
                """),
            Example("""
                var x: Int {
                    let a = 0

                    return a
                }
                """),
            Example("""
                #if os(macOS)
                let a = 0

                func f() {}
                #endif
                """),
            Example("""
                #warning("TODO: remove it")
                let a = 0
                #warning("TODO: remove it")
                let b = 0
                """),
            Example("""
                #error("TODO: remove it")
                let a = 0
                """),
            Example("""
                @available(swift 4)
                let a = 0
                """),
            Example("""
                @objc
                var s: String = ""
                """),
            Example("""
                @objc
                func a() {}
                """),
            Example("""
                var x = 0
                lazy
                var y = 0
                """),
            Example("""
                @available(OSX, introduced: 10.6)
                @available(*, deprecated)
                var x = 0
                """),
            Example("""
                // swiftlint:disable superfluous_disable_command
                // swiftlint:disable force_cast

                let x = bar as! Bar
                """),
            Example("""
                @available(swift 4)
                @UserDefault("param", defaultValue: true)
                var isEnabled = true

                @Attribute
                func f() {}
                """),
            // Don't trigger on local variable declarations.
            Example("""
                var x: Int {
                    let a = 0
                    return a
                }
                """),
            Example("""
                static var test: String { /* Comment block */
                    let s = "!"
                    return "Test" + s
                }

                func f() {}
                """, excludeFromDocumentation: true),
            Example(#"""
                @Flag(name: "name", help: "help")
                var fix = false
                @Flag(help: """
                        help
                        text
                """)
                var format = false
                @Flag(help: "help")
                var useAlternativeExcluding = false
                """#, excludeFromDocumentation: true),
        ].map(Self.wrapIntoClass) + [
            Example("""
                a = 2
                """),
            Example("""
                a = 2

                var b = 3
                """),
            Example("""
                #warning("message")
                let a = 2
                """),
            Example("""
                #if os(macOS)
                let a = 2
                #endif
                """),
            // Don't trigger in closure bodies.
            Example("""
                f {
                    let a = 1
                    return a
                }
                """),
            Example("""
                func f() {
                    #if os(macOS)
                    let a = 2
                    return a
                    #else
                    return 1
                    #endif
                }
                """),
        ],
        triggeringExamples: [
            Example("""
                let a
                ↓func x() {}
                """),
            Example("""
                var x = 0
                ↓@objc func f() {}
                """),
            Example("""
                var x = 0
                ↓@objc
                func f() {}
                """),
            Example("""
                @objc func f() {
                }
                ↓var x = 0
                """),
            Example("""
                func f() {}
                ↓@Wapper
                let isNumber = false
                @Wapper
                var isEnabled = true
                ↓func g() {}
                """),
            Example("""
                #if os(macOS)
                let a = 0
                ↓func f() {}
                #endif
                """),
        ].map(Self.wrapIntoClass) + [
            Example("""
                let a = 2
                ↓b = 1
                """),
            Example("""
                #if os(macOS)
                let a = 0
                ↓func f() {}
                #else
                func f() {}
                ↓let a = 1
                #endif
                """, excludeFromDocumentation: true),
        ]
    )

    private static func wrapIntoClass(_ example: Example) -> Example {
        example.with(code: "class C {\n" + example.code + "\n}")
    }
}

private extension LetVarWhitespaceRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: MemberBlockItemListSyntax) {
            collectViolations(from: node, using: { $0.decl }) // swiftlint:disable:this prefer_key_path
        }

        override func visitPost(_ node: CodeBlockItemListSyntax) {
            if node.isInValidContext {
                collectViolations(from: node, using: \.unwrap)
            }
        }

        private func collectViolations<List: SyntaxCollection>(from members: List,
                                                               using unwrap: (List.Element) -> any SyntaxProtocol) {
            for member in members {
                guard case let item = unwrap(member),
                      !item.is(MacroExpansionDeclSyntax.self),
                      !item.is(MacroExpansionExprSyntax.self),
                      let index = members.index(of: member),
                      case let nextIndex = members.index(after: index),
                      nextIndex != members.endIndex,
                      case let nextItem = unwrap(members[members.index(after: index)]),
                      !nextItem.is(MacroExpansionDeclSyntax.self),
                      !nextItem.is(MacroExpansionExprSyntax.self) else {
                    continue
                }
                if item.kind != nextItem.kind, item.kind == .variableDecl || nextItem.kind == .variableDecl,
                   !(item.trailingTrivia + nextItem.leadingTrivia).containsAtLeastTwoNewlines {
                    violations.append(nextItem.positionAfterSkippingLeadingTrivia)
                }
            }
        }
    }
}

private extension CodeBlockItemListSyntax {
    var isInValidContext: Bool {
        var next = parent
        while let ancestor = next {
            if [.closureExpr, .codeBlock, .accessorBlock].contains(ancestor.kind) {
                return false
            }
            if [.memberBlock, .sourceFile].contains(ancestor.kind) {
                return true
            }
            next = ancestor.parent
        }
        return false
    }
}

private extension Trivia {
    var containsAtLeastTwoNewlines: Bool {
        reduce(into: 0) { result, piece in
            if case let .newlines(number) = piece {
                result += number
            }
        } > 1
    }
}

private extension CodeBlockItemSyntax {
    var unwrap: any SyntaxProtocol {
        switch item {
        case let .decl(decl): decl
        case let .stmt(stmt): stmt
        case let .expr(expr): expr
        }
    }
}
