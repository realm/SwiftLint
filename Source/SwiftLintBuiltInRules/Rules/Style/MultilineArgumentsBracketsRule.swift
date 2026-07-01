import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct MultilineArgumentsBracketsRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "multiline_arguments_brackets",
        name: "Multiline Arguments Brackets",
        description: "Multiline arguments should have their surrounding brackets in a new line",
        kind: .style,
        nonTriggeringExamples: #examples([
            """
            foo(param1: "Param1", param2: "Param2", param3: "Param3")
            """,
            """
            foo(
                param1: "Param1", param2: "Param2", param3: "Param3"
            )
            """,
            """
            func foo(
                param1: "Param1",
                param2: "Param2",
                param3: "Param3"
            )
            """,
            """
            foo { param1, param2 in
                print("hello world")
            }
            """,
            """
            foo(
                bar(
                    x: 5,
                    y: 7
                )
            )
            """,
            """
            AlertViewModel.AlertAction(title: "some title", style: .default) {
                AlertManager.shared.presentNextDebugAlert()
            }
            """,
            """
            views.append(ViewModel(title: "MacBook", subtitle: "M1", action: { [weak self] in
                print("action tapped")
            }))
            """.excludeFromDocumentation(),
            """
            public final class Logger {
                public static let shared = Logger(outputs: [
                    OSLoggerOutput(),
                    ErrorLoggerOutput()
                ])
            }
            """,
            """
            let errors = try self.download([
                (description: description, priority: priority),
            ])
            """,
            """
            return SignalProducer({ observer, _ in
                observer.sendCompleted()
            }).onMainQueue()
            """,
            """
            SomeType(a: [
                1, 2, 3
            ], b: [1, 2])
            """,
            """
            SomeType(
              a: 1
            ) { print("completion") }
            """,
            """
            SomeType(
              a: 1
            ) {
              print("completion")
            }
            """,
            """
            SomeType(
              a: .init() { print("completion") }
            )
            """,
            """
            SomeType(
              a: .init() {
                print("completion")
              }
            )
            """,
            """
            SomeType(
              a: 1
            ) {} onError: {}
            """,
        ]),
        triggeringExamples: #examples([
            """
            foo(↓param1: "Param1", param2: "Param2",
                     param3: "Param3"
            )
            """,
            """
            foo(
                param1: "Param1",
                param2: "Param2",
                param3: "Param3"↓)
            """,
            """
            foo(↓param1: "Param1",
                param2: "Param2",
                param3: "Param3"↓)
            """,
            """
            foo(↓bar(
                x: 5,
                y: 7
            )
            )
            """,
            """
            foo(
                bar(
                    x: 5,
                    y: 7
            )↓)
            """,
            """
            SomeOtherType(↓a: [
                    1, 2, 3
                ],
                b: "two"↓)
            """,
            """
            SomeOtherType(
              a: 1↓) {}
            """,
            """
            SomeOtherType(
              a: 1↓) {
              print("completion")
            }
            """,
            """
            views.append(ViewModel(
                title: "MacBook", subtitle: "M1", action: { [weak self] in
                print("action tapped")
            }↓))
            """.excludeFromDocumentation(),
        ])
    )
}

private extension MultilineArgumentsBracketsRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard let firstArgument = node.arguments.first,
                  let leftParen = node.leftParen,
                  let rightParen = node.rightParen else {
                return
            }

            let hasMultilineFirstArgument = hasLeadingNewline(firstArgument)
            let hasMultilineArgument = node.arguments
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

        private func hasLeadingNewline(_ syntax: some SyntaxProtocol) -> Bool {
            syntax.leadingTrivia.contains(where: \.isNewline)
        }
    }
}
