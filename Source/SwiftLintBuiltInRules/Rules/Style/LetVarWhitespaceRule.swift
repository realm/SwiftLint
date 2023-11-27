import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule
struct LetVarWhitespaceRule: OptInRule {
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
            """#, excludeFromDocumentation: true)
        ].map(Self.wrapIntoClass),
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
            """)
        ].map(Self.wrapIntoClass)
    )

    private static func wrapIntoClass(_ example: Example) -> Example {
        example.with(code: "class C {\n" + example.code + "\n}")
    }
}

private extension LetVarWhitespaceRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: MemberBlockItemListSyntax) {
            if node.parent?.is(IfConfigClauseSyntax.self) != false {
                return
            }
            for member in node {
                let decl = member.decl
                guard !decl.is(MacroExpansionDeclSyntax.self),
                      let index = node.index(of: member),
                      case let nextIndex = node.index(after: index),
                      nextIndex != node.endIndex,
                      case let nextDecl = node[node.index(after: index)].decl,
                      !nextDecl.is(MacroExpansionDeclSyntax.self) else {
                    continue
                }
                if decl.kind != nextDecl.kind, decl.kind == .variableDecl || nextDecl.kind == .variableDecl,
                   !(decl.trailingTrivia + nextDecl.leadingTrivia).containsAtLeastTwoNewlines {
                    violations.append(nextDecl.positionAfterSkippingLeadingTrivia)
                }
            }
        }
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
