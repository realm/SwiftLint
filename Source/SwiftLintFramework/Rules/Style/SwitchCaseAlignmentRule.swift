import SwiftSyntax

struct SwitchCaseAlignmentRule: SwiftSyntaxRule, ConfigurationProviderRule {
    var configuration = SwitchCaseAlignmentConfiguration()

    init() {}

    static let description = RuleDescription(
        identifier: "switch_case_alignment",
        name: "Switch and Case Statement Alignment",
        description: """
            Case statements should vertically align with their enclosing switch statement, or indented if configured \
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
            """, excludeFromDocumentation: true)
        ],
        triggeringExamples: Examples(indentedCases: false).triggeringExamples
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(locationConverter: file.locationConverter, indentedCases: configuration.indentedCases)
    }
}

extension SwitchCaseAlignmentRule {
    private final class Visitor: ViolationsSyntaxVisitor {
        private let locationConverter: SourceLocationConverter
        private let indentedCases: Bool

        init(locationConverter: SourceLocationConverter, indentedCases: Bool) {
            self.locationConverter = locationConverter
            self.indentedCases = indentedCases
            super.init(viewMode: .sourceAccurate)
        }

        override func visitPost(_ node: SwitchExprSyntax) {
            let switchPosition = node.switchKeyword.positionAfterSkippingLeadingTrivia
            guard
                let switchColumn = locationConverter.location(for: switchPosition).column,
                node.cases.isNotEmpty,
                let firstCasePosition = node.cases.first?.positionAfterSkippingLeadingTrivia,
                let firstCaseColumn = locationConverter.location(for: firstCasePosition).column
            else {
                return
            }

            for `case` in node.cases where `case`.is(SwitchCaseSyntax.self) {
                let casePosition = `case`.positionAfterSkippingLeadingTrivia
                guard let caseColumn = locationConverter.location(for: casePosition).column else {
                    continue
                }

                let hasViolation = (indentedCases && caseColumn <= switchColumn) ||
                    (!indentedCases && caseColumn != switchColumn) ||
                    (indentedCases && caseColumn != firstCaseColumn)

                guard hasViolation else {
                    continue
                }

                let reason = """
                    Case statements should \
                    \(indentedCases ? "be indented within" : "vertically align with") \
                    their enclosing switch statement
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
            return (indentedCasesOption ? nonIndentedCases : indentedCases) + invalidCases
        }

        var nonTriggeringExamples: [Example] {
            return indentedCasesOption ? indentedCases : nonIndentedCases
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
                """)
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
                """)
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
                """)
            ]
        }
    }
}
