import SwiftSyntax
import SwiftSyntaxBuilder

struct SwitchCaseSortRule: ConfigurationProviderRule, SwiftSyntaxCorrectableRule, OptInRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }

    func makeRewriter(file: SwiftLintFile) -> ViolationsSyntaxRewriter? {
        Rewriter(
            locationConverter: file.locationConverter,
            disabledRegions: disabledRegions(file: file)
        )
    }

    static let description = RuleDescription(
        identifier: "sorted_switch_cases",
        name: "Sorted Switch Cases",
        description: "Switch cases should be sorted",
        kind: .style,
        nonTriggeringExamples: examples.nonTriggering,
        triggeringExamples: examples.triggering,
        corrections: examples.corrections
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

                let caseNames = caseLabelSyntax.caseItems.compactMap(sortableName)
                let caseNamesSorted = caseNames.sorted()
                if caseNames != caseNamesSorted {
                    violations.append(caseLabelSyntax.positionAfterSkippingLeadingTrivia)
                }

                return caseNamesSorted.first
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
        private let locationConverter: SourceLocationConverter
        private let disabledRegions: [SourceRange]

        init(locationConverter: SourceLocationConverter, disabledRegions: [SourceRange]) {
            self.locationConverter = locationConverter
            self.disabledRegions = disabledRegions
        }

        override func visit(_ node: SwitchExprSyntax) -> ExprSyntax {
            guard node.cases.isNotEmpty,
                  !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter)
            else {
                return super.visit(node)
            }

            let newCases = sort(node.cases)
            if node.cases.description != newCases.description {
                var newNode = node
                newNode.cases = newCases
                print("🦜", node, "\n", newNode)
                correctionPositions.append(node.switchKeyword.positionAfterSkippingLeadingTrivia)
                print("📍", correctionPositions)
                return super.visit(newNode)
            }

            return super.visit(node)
        }
    }
}

private func sort(_ cases: SwitchCaseListSyntax) -> SwitchCaseListSyntax {
    var elements = [SwitchCaseListSyntax.Element]()
    for caseListElement in cases {
        guard case let .switchCase(caseSyntax) = caseListElement,
              case let .case(caseLabelSyntax) = caseSyntax.label,
              !caseLabelSyntax.caseItems.isEmpty else {
            return cases
        }
        elements.append(.switchCase(caseSyntax.with(\.label, .case(sort(caseLabelSyntax)))))
    }

//    if cases.count == 1,
//       let caseLabelSyntax = cases.first,
//       case let .switchCase(switchCaseSyntax) = caseLabelSyntax,
//       case let .case(switchCaseLabelSyntax) = switchCaseSyntax.label {
//        var newSwitchCase: SwitchCaseSyntax = switchCaseSyntax
//
//        newSwitchCase.label = .case(sort(switchCaseLabelSyntax))
//
    ////            let newSwitchCase = SwitchCaseSyntax(
    ////                label: .case(sort(switchCaseLabelSyntax)),
    ////                statements: switchCaseSyntax.statements
    ////            )
//        return SwitchCaseListSyntax([.switchCase(newSwitchCase)])
//    }
//
    return SwitchCaseListSyntax(elements.sorted(by: byName))
}

private func sort(_ caseLabel: SwitchCaseLabelSyntax) -> SwitchCaseLabelSyntax {
    // remove trailing commas then sort them, then join them with commas
    let sortedItems = caseLabel.caseItems
            .map { $0.with(\.trailingComma, nil) }
            .sorted(by: byName)
            .enumerated()
            .map { index, item in
                index == caseLabel.caseItems.count - 1 ? item : item.with(\.trailingComma, ", ")
            }
        return caseLabel.with(\.caseItems, CaseItemListSyntax(sortedItems))
    
//    let itemsNoComma = caseLabel.caseItems.map { item in
//        item.with(\.trailingComma, nil)
//    }
//
//    let sortedNoComma = itemsNoComma.sorted(by: byName)
//    let sortedWithComma = sortedNoComma.enumerated().map { index, item in
//        if index == sortedNoComma.count - 1 {
//            return item
//        } else {
//            return item.with(\.trailingComma, ",")
//        }
//    }
//    return caseLabel.with(\.caseItems, CaseItemListSyntax(sortedWithComma))
}

private func sortableName(for caseItemSyntax: CaseItemSyntax) -> String? {
    if let expressionPattern = caseItemSyntax.pattern.as(ExpressionPatternSyntax.self) {
        if let memberAccessExpression = expressionPattern.expression
            .as(MemberAccessExprSyntax.self) {
            return memberAccessExpression.name.text
        } else if let stringLiteralExpression = expressionPattern.expression
            .as(StringLiteralExprSyntax.self) {
            let segments = stringLiteralExpression.segments.map { segment in
                switch segment {
                // ignore interpolation and join the string literals
                case let .stringSegment(segment):
                    return segment.content.text
                case .expressionSegment: // string interpolation part
                    return ""
                }
            }.joined()
            return segments.isEmpty ? nil : segments
        } else if let identifierExpression = expressionPattern.expression
            .as(IdentifierExprSyntax.self) {
            return identifierExpression.identifier.text
        }
    }
    return nil
}

private func sortableName(for caseLabelSyntax: SwitchCaseLabelSyntax) -> String? {
    if let item = caseLabelSyntax.caseItems.first {
        return sortableName(for: item)
    }
    return nil
}

private func byName(_ lhs: CaseItemSyntax, _ rhs: CaseItemSyntax) -> Bool {
    guard let lhsName = sortableName(for: lhs),
          let rhsName = sortableName(for: rhs) else {
        return false
    }
    return lhsName < rhsName
}

private func byName(_ lhs: SwitchCaseLabelSyntax, _ rhs: SwitchCaseLabelSyntax) -> Bool {
    guard let lhsName = sortableName(for: lhs),
          let rhsName = sortableName(for: rhs) else {
        return false
    }
    return lhsName < rhsName
}

private func byName(_ lhs: SwitchCaseSyntax, _ rhs: SwitchCaseSyntax) -> Bool {
    switch (lhs.label, rhs.label) {
    // default is always last
    case (.default, _):
        return false
    case (_, .default):
        return true
    case let (.case(lhsCaseLabel), .case(rhsCaseLabel)):
        return byName(lhsCaseLabel, rhsCaseLabel)
    }
}

private func byName(_ lhs: SwitchCaseListSyntax.Element, _ rhs: SwitchCaseListSyntax.Element) -> Bool {
    switch (lhs, rhs) {
    case let (.switchCase(lhsSwitchCase), .switchCase(rhsSwitchCase)):
        return byName(lhsSwitchCase, rhsSwitchCase)
    case (.ifConfigDecl(_), _):
        return false
    case (_, .ifConfigDecl(_)):
        return true
    }
}

private func byName(_ lhs: SwitchCaseListSyntax, _ rhs: SwitchCaseListSyntax) -> Bool {
    switch (lhs.first!, rhs.first!) {
    case let (.switchCase(lhsSwitchCase), .switchCase(rhsSwitchCase)):
        return byName(lhsSwitchCase, rhsSwitchCase)
    case (.ifConfigDecl(_), _):
        return false
    case (_, .ifConfigDecl(_)):
        return true
    }
}

/*
 SwitchCaseListSyntax
 > case `switchCase`(SwitchCaseSyntax)
 >> SwitchCaseSyntax
 >>> case `default`(SwitchDefaultLabelSyntax)
 >>> case `case`(SwitchCaseLabelSyntax)
 >>>> SwitchCaseLabelSyntax
 >>>>> \.caseItems: CaseItemListSyntax
 >>>>>> [CaseItemSyntax]
 > case `ifConfigDecl`(IfConfigDeclSyntax) // `case` expression is inside #if...#endif
 >> IfConfigDeclSyntax
 >>> \.clauses: IfConfigClauseListSyntax
 >>>> IfConfigClauseSyntax
 >>>>> case `statements`(CodeBlockItemListSyntax)
 >>>>> case `switchCases`(SwitchCaseListSyntax)
 >>>>> case `decls`(MemberDeclListSyntax)
 >>>>> case `postfixExpression`(ExprSyntax)
 >>>>> case `attributes`(AttributeListSyntax)
 */

// to see the triggering and correction subsequently
private let examples: (triggering: [Example], nonTriggering: [Example], corrections: [Example: Example]) = {
    var triggering = [Example]()
    var nonTriggering = [Example]()
//    var corrections = [Example: Example]()
    triggering.append(
        Example("""
        ↓switch foo {
        case .b:
            break
        case .a:
            break
        case .c:
            break
        }
        """)
    )
    nonTriggering.append(
        Example("""
        switch foo {
        case .a:
            break
        case .b:
            break
        case .c:
            break
        }
        """)
    )
    triggering.append(
        Example("""
        switch foo {
        ↓case .b, .a, .c:
            break
        }
        """)
    )
    nonTriggering.append(
        Example("""
        switch foo {
        case .a, .b, .c:
            break
        }
        """)
    )
    triggering.append(
        Example("""
        switch foo {
        case .a:
            break
        ↓case .c, .b:
            break
        }
        """)
    )
    nonTriggering.append(
        Example("""
        switch foo {
        case .a:
            break
        case .b, .c:
            break
        }
        """)
    )
    triggering.append(
        Example("""
        ↓switch foo {
        case .z:
            break
        ↓case .c, .b:
            break
        }
        """)
    )
    nonTriggering.append(
        Example("""
        switch foo {
        case .b, .c:
            break
        case .z:
            break
        }
        """)
    )
    triggering.append(
        Example("""
        ↓switch foo {
        case .d:
            break
        case .a:
            break
        case default:
            break
        }
        """)
    )
    nonTriggering.append(
        Example("""
        switch foo {
        case .a:
            break
        case .d:
            break
        case default:
            break
        }
        """)
    )

    let corrections: [Example: Example] = {
        var result: [Example: Example] = [:]
        for (triggering, correction) in zip(triggering, nonTriggering) {
            // correction location is always before switch keyword
            let toBeCorrectted = triggering.with(
                code: triggering.code.replacingOccurrences(of: "↓", with: "")
                    .replacingOccurrences(of: "switch", with: "↓switch")
            )
            result[toBeCorrectted] = correction
        }
        return result
    }()

    return (triggering, nonTriggering, corrections)
}()


enum Foo {
    case a, b, c
}
func dene() {
    let foo = Foo.a
    switch foo {
    case .a:
        break
    case .b, .c:
        break
    }
}

