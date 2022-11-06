import SwiftSyntax

struct MultilineArgumentsBracketsRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "multiline_arguments_brackets",
        name: "Multiline Arguments Brackets",
        description: "Multiline arguments should have their surrounding brackets in a new line",
        kind: .style,
        nonTriggeringExamples: [
            Example("""
            foo(param1: "Param1", param2: "Param2", param3: "Param3")
            """),
            Example("""
            foo(
                param1: "Param1", param2: "Param2", param3: "Param3"
            )
            """),
            Example("""
            func foo(
                param1: "Param1",
                param2: "Param2",
                param3: "Param3"
            )
            """),
            Example("""
            foo { param1, param2 in
                print("hello world")
            }
            """),
            Example("""
            foo(
                bar(
                    x: 5,
                    y: 7
                )
            )
            """),
            Example("""
            AlertViewModel.AlertAction(title: "some title", style: .default) {
                AlertManager.shared.presentNextDebugAlert()
            }
            """),
            Example("""
            views.append(ViewModel(title: "MacBook", subtitle: "M1", action: { [weak self] in
                print("action tapped")
            }))
            """, excludeFromDocumentation: true),
            Example("""
            public final class Logger {
                public static let shared = Logger(outputs: [
                    OSLoggerOutput(),
                    ErrorLoggerOutput()
                ])
            }
            """),
            Example("""
            let errors = try self.download([
                (description: description, priority: priority),
            ])
            """),
            Example("""
            return SignalProducer({ observer, _ in
                observer.sendCompleted()
            }).onMainQueue()
            """),
            Example("""
            SomeType(a: [
                1, 2, 3
            ], b: [1, 2])
            """),
            Example("""
            SomeType(
              a: 1
            ) { print("completion") }
            """),
            Example("""
            SomeType(
              a: 1
            ) {
              print("completion")
            }
            """),
            Example("""
            SomeType(
              a: .init() { print("completion") }
            )
            """),
            Example("""
            SomeType(
              a: .init() {
                print("completion")
              }
            )
            """),
            Example("""
            SomeType(
              a: 1
            ) {} onError: {}
            """)
        ],
        triggeringExamples: [
            Example("""
            foo(↓param1: "Param1", param2: "Param2",
                     param3: "Param3"
            )
            """),
            Example("""
            foo(
                param1: "Param1",
                param2: "Param2",
                param3: "Param3"↓)
            """),
            Example("""
            foo(↓param1: "Param1",
                param2: "Param2",
                param3: "Param3"↓)
            """),
            Example("""
            foo(↓bar(
                x: 5,
                y: 7
            )
            )
            """),
            Example("""
            foo(
                bar(
                    x: 5,
                    y: 7
            )↓)
            """),
            Example("""
            SomeOtherType(↓a: [
                    1, 2, 3
                ],
                b: "two"↓)
            """),
            Example("""
            SomeOtherType(
              a: 1↓) {}
            """),
            Example("""
            SomeOtherType(
              a: 1↓) {
              print("completion")
            }
            """),
            Example("""
            views.append(ViewModel(
                title: "MacBook", subtitle: "M1", action: { [weak self] in
                print("action tapped")
            }↓))
            """, excludeFromDocumentation: true)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension MultilineArgumentsBracketsRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard let firstArgument = node.argumentList.first,
                  let leftParen = node.leftParen,
                  let rightParen = node.rightParen else {
                return
            }

            let hasMultilineFirstArgument = hasLeadingNewline(firstArgument)
            let hasMultilineArgument = node.argumentList
                .contains { argument in
                    hasLeadingNewline(argument)
                }

            let hasMultilineRightParen = hasLeadingNewline(rightParen)

            if !hasMultilineFirstArgument, hasMultilineArgument {
                violations.append(leftParen.endPosition)
            }

            if !hasMultilineArgument, hasMultilineRightParen {
                violations.append(leftParen.endPosition)
            }

            if !hasMultilineRightParen, hasMultilineArgument {
                violations.append(rightParen.position)
            }
        }

        private func hasLeadingNewline(_ syntax: SyntaxProtocol) -> Bool {
            guard let leadingTrivia = syntax.leadingTrivia else { return false }

            return leadingTrivia.pieces.contains { $0.isNewline }
        }
    }
}
