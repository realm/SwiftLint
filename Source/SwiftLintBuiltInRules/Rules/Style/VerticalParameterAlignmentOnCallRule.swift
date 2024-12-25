import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct VerticalParameterAlignmentOnCallRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "vertical_parameter_alignment_on_call",
        name: "Vertical Parameter Alignment on Call",
        description: "Function parameters should be aligned vertically if they're in multiple lines in a method call",
        kind: .style,
        nonTriggeringExamples: [
            Example("""
            foo(param1: 1, param2: bar
                param3: false, param4: true)
            """),
            Example("""
            foo(param1: 1, param2: bar)
            """),
            Example("""
            foo(param1: 1, param2: bar
                param3: false,
                param4: true)
            """),
            Example("""
            foo(
               param1: 1
            ) { _ in }
            """),
            Example("""
            UIView.animate(withDuration: 0.4, animations: {
                blurredImageView.alpha = 1
            }, completion: { _ in
                self.hideLoading()
            })
            """),
            Example("""
            UIView.animate(withDuration: 0.4, animations: {
                blurredImageView.alpha = 1
            },
            completion: { _ in
                self.hideLoading()
            })
            """),
            Example("""
            UIView.animate(withDuration: 0.4, animations: {
                blurredImageView.alpha = 1
            } { _ in
                self.hideLoading()
            }
            """),
            Example("""
            foo(param1: 1, param2: { _ in },
                param3: false, param4: true)
            """),
            Example("""
            foo({ _ in
                   bar()
               },
               completion: { _ in
                   baz()
               }
            )
            """),
            Example("""
            foo(param1: 1, param2: [
               0,
               1
            ], param3: 0)
            """),
            Example("""
            myFunc(foo: 0,
                   bar: baz == 0)
            """),
            Example("""
            UIViewPropertyAnimator.runningPropertyAnimator(
                withDuration: 2.0,
                delay: 0.0,
                options: [.curveEaseIn]
            ) {
                // animations
            } completion: { _ in
                // completion
            }
            """),
        ],
        triggeringExamples: [
            Example("""
            foo(param1: 1, param2: bar,
                            ↓param3: false, param4: true)
            """),
            Example("""
            foo(param1: 1, param2: bar,
             ↓param3: false, param4: true)
            """),
            Example("""
            foo(param1: 1, param2: bar,
                   ↓param3: false,
                   ↓param4: true)
            """),
            Example("""
            foo(param1: 1,
                   ↓param2: { _ in })
            """),
            Example("""
            foo(param1: 1,
                param2: { _ in
            }, param3: 2,
             ↓param4: 0)
            """),
            Example("""
            foo(param1: 1, param2: { _ in },
                   ↓param3: false, param4: true)
            """),
            Example("""
            myFunc(foo: 0,
                    ↓bar: baz == 0)
            """),
            Example("""
            myFunc(foo: 0, bar:
                    baz == 0, ↓baz: true)
            """),
        ]
    )
}

private extension VerticalParameterAlignmentOnCallRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            let arguments = node.arguments
            guard arguments.count > 1, let firstArg = arguments.first else {
                return
            }

            var firstArgumentLocation = locationConverter.location(for: firstArg.positionAfterSkippingLeadingTrivia)

            var visitedLines = Set<Int>()
            var previousArgumentWasMultiline = false

            let violatingPositions: [AbsolutePosition] = arguments
                .compactMap { argument -> AbsolutePosition? in
                    defer {
                        previousArgumentWasMultiline = isMultiline(argument: argument)
                    }

                    let position = argument.positionAfterSkippingLeadingTrivia
                    let location = locationConverter.location(for: position)
                    guard location.line > firstArgumentLocation.line else {
                        return nil
                    }

                    let (firstVisit, _) = visitedLines.insert(location.line)
                    guard location.column != firstArgumentLocation.column && firstVisit else {
                        return nil
                    }

                    // if this is the first element on a new line after a closure with multiple lines,
                    // we reset the reference position
                    if previousArgumentWasMultiline && firstVisit {
                        firstArgumentLocation = location
                        return nil
                    }

                    return position
                }

            violations.append(contentsOf: violatingPositions)
        }

        private func isMultiline(argument: LabeledExprListSyntax.Element) -> Bool {
            let expression = argument.expression
            let startPosition = locationConverter.location(for: expression.positionAfterSkippingLeadingTrivia)
            let endPosition = locationConverter.location(for: expression.endPositionBeforeTrailingTrivia)

            return endPosition.line > startPosition.line
        }
    }
}
