import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct ShorthandArgumentRule: Rule {
    var configuration = ShorthandArgumentConfiguration()

    static let description = RuleDescription(
        identifier: "shorthand_argument",
        name: "Shorthand Argument",
        description: """
            Shorthand arguments like `$0`, `$1`, etc. in closures can be confusing. Avoid using them too far \
            away from the beginning of the closure. Optionally, while usage of a single shorthand argument is okay, \
            more than one or complex ones with field accesses might increase the risk of obfuscation.
            """,
        kind: .style,
        nonTriggeringExamples: [
            Example("""
                f { $0 }
                """),
            Example("""
                f {
                    $0
                  + $1
                  + $2
                }
                """),
            Example("""
                f { $0.a + $0.b }
                """),
            Example("""
                f {
                    $0
                  +  g { $0 }
                """, configuration: ["allow_until_line_after_opening_brace": 1]),
        ],
        triggeringExamples: [
            Example("""
                f {
                    $0
                  + $1
                  + $2

                  + ↓$0
                }
                """),
            Example("""
                f {
                    $0
                  + $1
                  + $2
                  +  5
                  + $0
                  + ↓$1
                }
                """, configuration: ["allow_until_line_after_opening_brace": 5]),
            Example("""
                f { ↓$0 + ↓$1 }
                """, configuration: ["always_disallow_more_than_one": true]),
            Example("""
                f {
                    ↓$0.a
                  + ↓$0.b
                  + $1
                  + ↓$2.c
                }
                """, configuration: ["always_disallow_member_access": true, "allow_until_line_after_opening_brace": 3]),
        ]
    )
}

private extension ShorthandArgumentRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: ClosureExprSyntax) {
            let arguments = ShorthandArgumentCollector().walk(tree: node.statements, handler: \.arguments)
            if configuration.alwaysDisallowMoreThanOne {
                if arguments.map(\.name).unique.count > 1 {
                    violations.append(contentsOf: arguments.map {
                        ReasonedRuleViolation(
                            position: $0.position,
                            reason: "Multiple different shorthand arguments should be avoided",
                            severity: configuration.severity
                        )
                    })
                    // In this case, the rule triggers on all shorthand arguments, thus exit here.
                    return
                }
            }
            let complexArguments = arguments.filter(\.isComplex)
            if configuration.alwaysDisallowMemberAccess {
                if complexArguments.isNotEmpty {
                    violations.append(contentsOf: complexArguments.map {
                        ReasonedRuleViolation(
                            position: $0.position,
                            reason: "Accessing members of shorthand arguments should be avoided",
                            severity: configuration.severity
                        )
                    })
                }
            }
            let startLine = node.startLocation(converter: locationConverter, afterLeadingTrivia: true).line
            violations.append(contentsOf: arguments.compactMap { argument -> ReasonedRuleViolation? in
                if complexArguments.contains(argument) {
                    nil
                } else if locationConverter.location(for: argument.position).line
                          <= startLine + configuration.allowUntilLineAfterOpeningBrace {
                    nil
                } else {
                    ReasonedRuleViolation(
                        position: argument.position,
                        reason: """
                            References to shorthand arguments too far away from the closure's beginning should \
                            be avoided
                            """,
                        severity: configuration.severity
                    )
                }
            })
        }
    }
}

private struct ShorthandArgument: Hashable {
    let name: String
    let position: AbsolutePosition
    let isComplex: Bool
}

private final class ShorthandArgumentCollector: SyntaxVisitor {
    private(set) var arguments = Set<ShorthandArgument>()

    init() {
        super.init(viewMode: .sourceAccurate)
    }

    override func visitPost(_ node: DeclReferenceExprSyntax) {
        if case let .dollarIdentifier(name) = node.baseName.tokenKind {
            arguments.insert(
                ShorthandArgument(
                    name: name,
                    position: node.positionAfterSkippingLeadingTrivia,
                    isComplex: node.keyPathInParent == \MemberAccessExprSyntax.base
                )
            )
        }
    }

    override func visit(_: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
        .skipChildren
    }
}
