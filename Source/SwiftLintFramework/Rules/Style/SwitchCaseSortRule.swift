import SwiftSyntax

struct SwitchCaseSortRule: ConfigurationProviderRule, SwiftSyntaxCorrectableRule, OptInRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }

    func makeRewriter(file: SwiftLintFile) -> ViolationsSyntaxRewriter? {
        Rewriter()
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
            switch foo {
            ↓case .b, .a, .c:
                break
            }
            """),
            Example("""
            switch foo {
            case .a:
                break
            ↓case .c, .b:
                break
            }
            """),
            Example("""
            ↓switch foo {
            case .z:
                break
            ↓case .c, .b:
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

private extension SwitchCaseSortRule {
//    final class Visitor: ViolationsSyntaxVisitor {
//        override func visitPost(_ node: SwitchExprSyntax) {
//            guard node.cases.isNotEmpty else {
//                return
//            }
//
//            var caseNamesToSort = [String]()
//
//            for caseListSyntax in node.cases {
//                switch caseListSyntax {
//                case let .switchCase(caseSyntax):
//                    switch caseSyntax.label {
//                    case let .default(defaultLabelSyntax):
//                        // xcode already warns if default is not at the end?
//                        continue
//                    case let .case(caseLabelSyntax):
//                        if caseLabelSyntax.caseItems.isEmpty {
//                            continue
//                        }
//                        if caseLabelSyntax.caseItems.count == 1 {
//                            // get the name for top level sortation
//                            let name = sortableName(for: caseLabelSyntax.caseItems.first!)
//                            caseNamesToSort.append(name)
//                        } else { // multiple items in one case expression
//                            // sort them among themselves
//                            var caseNames = [String]()
//                            for caseItem in caseLabelSyntax.caseItems {
//                                let name = sortableName(for: caseItem)
//                                caseNames.append(name)
//                            }
//                            let sortedCaseNames = caseNames.sorted()
//                            if caseNames != sortedCaseNames {
//                                violations.append(caseLabelSyntax.positionAfterSkippingLeadingTrivia)
//                            }
//                            caseNamesToSort.append(sortedCaseNames.first!)
//                        }
//                    }
//                case .ifConfigDecl:
//                    continue
//                }
//            }
//
//            let sortedCaseNames = caseNamesToSort.sorted()
//            if caseNamesToSort != sortedCaseNames {
//                violations.append(node.switchKeyword.positionAfterSkippingLeadingTrivia)
//            }
//        }
//    }

    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: SwitchExprSyntax) {
            guard node.cases.isNotEmpty else {
                return
            }

            let caseNamesToSort = node.cases.compactMap { caseListSyntax -> String? in
                guard case let .switchCase(caseSyntax) = caseListSyntax,
                      case let .case(caseLabelSyntax) = caseSyntax.label,
                      !caseLabelSyntax.caseItems.isEmpty else {
                    return nil
                }

                let caseNames = caseLabelSyntax.caseItems.map(sortableName).sorted()
                if caseNames != caseLabelSyntax.caseItems.map(sortableName) {
                    violations.append(caseLabelSyntax.positionAfterSkippingLeadingTrivia)
                }

                return caseNames.first
            }

            let sortedCaseNames = caseNamesToSort.sorted()
            if caseNamesToSort != sortedCaseNames {
                violations.append(node.switchKeyword.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}

private extension SwitchCaseSortRule {
    final class Rewriter: SyntaxRewriter, ViolationsSyntaxRewriter {
        private(set) var correctionPositions: [AbsolutePosition] = []

        override func visit(_ node: SwitchExprSyntax) -> ExprSyntax {
            guard node.cases.isNotEmpty else {
                return super.visit(node)
            }

            return super.visit(node)
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
                case .expressionSegment: // string interpolation part
                    return ""
                }
            }.joined()
        } else if let identifierExpression = expressionPattern.expression
            .as(IdentifierExprSyntax.self) {
            return identifierExpression.identifier.text
        }
    }
    return "" // return String? = nil
}

private func sortableName(for caseLabelSyntax: SwitchCaseLabelSyntax) -> String {
    if let item = caseLabelSyntax.caseItems.first {
        return sortableName(for: item)
    }
    return ""
}

private func byName(_ lhs: CaseItemSyntax, _ rhs: CaseItemSyntax) -> Bool {
    sortableName(for: lhs) < sortableName(for: rhs)
}

private func byName(_ lhs: SwitchCaseLabelSyntax, _ rhs: SwitchCaseLabelSyntax) -> Bool {
    let newLhs = SwitchCaseLabelSyntax(caseItems: CaseItemListSyntax(lhs.caseItems.sorted(by: byName)))
    let newRhs = SwitchCaseLabelSyntax(caseItems: CaseItemListSyntax(rhs.caseItems.sorted(by: byName)))
    return sortableName(for: newLhs) < sortableName(for: newRhs)
}
