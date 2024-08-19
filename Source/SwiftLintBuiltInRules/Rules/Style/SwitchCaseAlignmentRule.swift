import SwiftSyntax

@SwiftSyntaxRule
struct SwitchCaseAlignmentRule: Rule {
    var configuration = SwitchCaseAlignmentConfiguration()

    static let description = RuleDescription(
        identifier: "switch_case_alignment",
        name: "Switch and Case Statement Alignment",
        description: """
            Case statements should vertically align with their closing brace, or indented if configured \
            otherwise.
            """,
        kind: .style,
        nonTriggeringExamples: Examples(indentedCases: false).nonTriggeringExamples + [
            Example("""
            extension OSLogFloatFormatting {
              /// Returns a fprintf-compatible length modifier for a given argument type
              @_semantics("constant_evaluable")
              @inlinable
              @_optimize(none)
              internal static func _formatStringLengthModifier<I: FloatingPoint>(
                _ type: I.Type
              ) -> String? {
                switch type {
                //   fprintf formatters promote Float to Double
                case is Float.Type: return ""
                case is Double.Type: return ""
            #if !os(Windows) && (arch(i386) || arch(x86_64))
                //   fprintf formatters use L for Float80
                case is Float80.Type: return "L"
            #endif
                default: return nil
                }
              }
            }
            """, excludeFromDocumentation: true),
        ],
        triggeringExamples: Examples(indentedCases: false).triggeringExamples
    )
}

extension SwitchCaseAlignmentRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: SwitchExprSyntax) {
            guard node.cases.isNotEmpty,
                  let firstCasePosition = node.cases.first?.positionAfterSkippingLeadingTrivia
            else {
                return
            }

            let closingBracePosition = node.rightBrace.positionAfterSkippingLeadingTrivia
            let closingBraceLocation = locationConverter.location(for: closingBracePosition)
            let switchKeywordPosition = node.switchKeyword.positionAfterSkippingLeadingTrivia
            let switchKeywordLocation = locationConverter.location(for: switchKeywordPosition)

            if configuration.ignoreOneLiners && switchKeywordLocation.line == closingBraceLocation.line {
                return
            }

            let closingBraceColumn = closingBraceLocation.column
            let firstCaseColumn = locationConverter.location(for: firstCasePosition).column

            for `case` in node.cases where `case`.is(SwitchCaseSyntax.self) {
                let casePosition = `case`.positionAfterSkippingLeadingTrivia
                let caseColumn = locationConverter.location(for: casePosition).column

                let hasViolation = (configuration.indentedCases && caseColumn <= closingBraceColumn) ||
                    (!configuration.indentedCases && caseColumn != closingBraceColumn) ||
                    (configuration.indentedCases && caseColumn != firstCaseColumn)

                guard hasViolation else {
                    continue
                }

                let reason = """
                    Case statements should \
                    \(configuration.indentedCases ? "be indented within" : "vertically aligned with") \
                    their closing brace
                    """

                violations.append(ReasonedRuleViolation(position: casePosition, reason: reason))
            }
        }
    }

    struct Examples {
        private let indentedCasesOption: Bool
        private let violationMarker = "↓"

        init(indentedCases: Bool) {
            self.indentedCasesOption = indentedCases
        }

        var triggeringExamples: [Example] {
            (indentedCasesOption ? nonIndentedCases : indentedCases)
                + invalidCases
                + invalidOneLiners
        }

        var nonTriggeringExamples: [Example] {
            indentedCasesOption ? indentedCases : nonIndentedCases + validOneLiners
        }

        private var indentedCases: [Example] {
            let violationMarker = indentedCasesOption ? "" : self.violationMarker

            return [
                Example("""
                switch someBool {
                    \(violationMarker)case true:
                        print("red")
                    \(violationMarker)case false:
                        print("blue")
                }
                """),
                Example("""
                if aBool {
                    switch someBool {
                        \(violationMarker)case true:
                            print('red')
                        \(violationMarker)case false:
                            print('blue')
                    }
                }
                """),
                Example("""
                switch someInt {
                    \(violationMarker)case 0:
                        print('Zero')
                    \(violationMarker)case 1:
                        print('One')
                    \(violationMarker)default:
                        print('Some other number')
                }
                """),
                Example("""
                let a = switch i {
                    \(violationMarker)case 1: 1
                    \(violationMarker)default: 2
                }
                """),
            ]
        }

        private var nonIndentedCases: [Example] {
            let violationMarker = indentedCasesOption ? self.violationMarker : ""

            return [
                Example("""
                switch someBool {
                \(violationMarker)case true: // case 1
                    print('red')
                \(violationMarker)case false:
                    /*
                    case 2
                    */
                    if case let .someEnum(val) = someFunc() {
                        print('blue')
                    }
                }
                enum SomeEnum {
                    case innocent
                }
                """),
                Example("""
                if aBool {
                    switch someBool {
                    \(violationMarker)case true:
                        print('red')
                    \(violationMarker)case false:
                        print('blue')
                    }
                }
                """),
                Example("""
                switch someInt {
                // comments ignored
                \(violationMarker)case 0:
                    // zero case
                    print('Zero')
                \(violationMarker)case 1:
                    print('One')
                \(violationMarker)default:
                    print('Some other number')
                }
                """),
                Example("""
                func f() -> Int {
                    return switch i {
                    \(violationMarker)case 1: 1
                    \(violationMarker)default: 2
                    }
                }
                """),
            ]
        }

        private var invalidCases: [Example] {
            let indentation = indentedCasesOption ? "    " : ""

            return [
                Example("""
                switch someBool {
                \(indentation)case true:
                    \(indentation)print('red')
                    \(indentation)\(violationMarker)case false:
                        \(indentation)print('blue')
                }
                """),
                Example("""
                if aBool {
                    switch someBool {
                        \(indentation)\(indentedCasesOption ? "" : violationMarker)case true:
                        \(indentation)print('red')
                    \(indentation)\(indentedCasesOption ? violationMarker : "")case false:
                    \(indentation)print('blue')
                    }
                }
                """),
                Example("""
                let a = switch i {
                \(indentation)case 1: 1
                    \(indentation)\(indentedCasesOption ? "" : violationMarker)default: 2
                }
                """),
            ]
        }

        private var validOneLiners: [Example] = [
            Example(
                "switch i { case .x: 1 default: 0 }",
                configuration: ["ignore_one_liners": true]
            ),
            Example(
                "let a = switch i { case .x: 1 default: 0 }",
                configuration: ["ignore_one_liners": true]
            ),
        ]

        private var invalidOneLiners: [Example] {
            [
                // Default configuration should not ignore one liners
                Example(
                    "switch i { \(violationMarker)case .x: 1 \(violationMarker)default: 0 }"
                ),
                Example("""
                switch i {
                \(violationMarker)case .x: 1 \(violationMarker)default: 0 }
                """, configuration: ["ignore_one_liners": true]),
                Example("""
                switch i { \(violationMarker)case .x: 1 \(violationMarker)default: 0
                }
                """, configuration: ["ignore_one_liners": true]),
                Example("""
                switch i
                { \(violationMarker)case .x: 1 \(violationMarker)default: 0 }
                """, configuration: ["ignore_one_liners": true]),
                Example("""
                let a = switch i {
                case .x: 1 \(violationMarker)default: 0
                }
                """, configuration: ["ignore_one_liners": true]),
                Example("""
                let a = switch i {
                \(violationMarker)case .x: 1 \(violationMarker)default: 0 }
                """, configuration: ["ignore_one_liners": true]),
            ]
        }
    }
}
