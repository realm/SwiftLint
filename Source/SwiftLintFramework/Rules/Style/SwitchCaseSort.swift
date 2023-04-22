import SwiftSyntax

struct SwitchCaseSort: ConfigurationProviderRule, SwiftSyntaxRule, OptInRule {
    var configuration = SeverityConfiguration(.warning)

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }

    static let description = RuleDescription(
        identifier: "sorted_switch_cases",
        name: "Sorted Switch Cases",
        description: "Switch cases should be sorted",
        kind: .style,
        nonTriggeringExamples: [
            Example("""
            switch foo {
            case .a:
                break
            case .b:
                break
            case .c:
                break
            }
            """),
            Example("""
            switch foo {
            case .a, .b, .c:
                break
            }
            """),
            Example("""
            switch foo {
            case .a:
                break
            case .b, .c:
                break
            }
            """),
            Example("""
            switch foo {
            case .a(let foo):
                break
            case .b(let bar), .c:
                break
            }
            """),
            Example("""
            switch foo {
            case .b:
                break
            case .a:
                break
            case .c, .f, .d:
                break
            }
            """),
            Example("""
            switch foo {
            case .a:
                break
            case .b:
                break
            default:
                break
            }
            """),
        ],
        triggeringExamples: [
            Example("""
            ↓switch foo {
            case .b:
                break
            case .a:
                break
            case .c:
                break
            }
            """),
            Example("""
            ↓switch foo {
            case .b, .a, .c:
                break
            }
            """),
            Example("""
            ↓switch foo {
            case .d:
                break
            case .a:
                break
            case default:
                break
            }
            """),
        ]
    )
}

private extension SwitchCaseSort {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: SwitchExprSyntax) {
            guard node.cases.isNotEmpty else {
                return
            }

            var caseNamesToSort = [String]()

            for caseListSyntax in node.cases {
                if let caseSyntax = caseListSyntax.as(SwitchCaseSyntax.self) {
                    switch caseSyntax.label {
                    case let .default(defaultLabelSyntax):
                        print(defaultLabelSyntax)
                    case let .case(caseLabelSyntax):
                        if caseLabelSyntax.caseItems.count == 1 {
                            // get the name for top level sortation
                            let name = sortableName(for: caseLabelSyntax.caseItems.first!)
                            caseNamesToSort.append(name)
                        } else { // multiple items in one case expression
                            // sort them among themselves
                            var caseNames = [String]()
                            for caseItem in caseLabelSyntax.caseItems {
                                let name = sortableName(for: caseItem)
                                caseNames.append(name)
                            }
                            let sortedCaseNames = caseNames.sorted()
                            if caseNames != sortedCaseNames {
                                violations.append(caseLabelSyntax.positionAfterSkippingLeadingTrivia)
                            }
                            caseNamesToSort.append(sortedCaseNames.first!)
                        }
                    }
                }
            }

            let sortedCaseNames = caseNamesToSort.sorted()
            if caseNamesToSort != sortedCaseNames {
                violations.append(node.switchKeyword.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}

private func sortableName(for caseItemSyntax: CaseItemSyntax) -> String {
    if let expressionPattern = caseItemSyntax.pattern.as(ExpressionPatternSyntax.self) {
        if let memberAccessExpression = expressionPattern.expression
            .as(MemberAccessExprSyntax.self) {
            return memberAccessExpression.name.text
        } else if let stringLiteralExpression = expressionPattern.expression
            .as(StringLiteralExprSyntax.self) {
            return stringLiteralExpression.segments.map { segment in
                switch segment {
                // ignore interpolation and join the string literals
                case let .stringSegment(segment):
                    return segment.content.text
                case .expressionSegment: // string interpolation
                    return ""
                }
            }.joined()
        } else if let identifierExpression = expressionPattern.expression
            .as(IdentifierExprSyntax.self) {
            return identifierExpression.identifier.text
        }
    }
    return "" // TODO: return String? = nil
}
