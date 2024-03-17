import SwiftSyntax

@SwiftSyntaxRule
struct UnusedEnumeratedRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "unused_enumerated",
        name: "Unused Enumerated",
        description: "When the index or the item is not used, `.enumerated()` can be removed.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("for (idx, foo) in bar.enumerated() { }"),
            Example("for (_, foo) in bar.enumerated().something() { }"),
            Example("for (_, foo) in bar.something() { }"),
            Example("for foo in bar.enumerated() { }"),
            Example("for foo in bar { }"),
            Example("for (idx, _) in bar.enumerated().something() { }"),
            Example("for (idx, _) in bar.something() { }"),
            Example("for idx in bar.indices { }"),
            Example("for (section, (event, _)) in data.enumerated() {}"),
            Example("list.enumerated().map { idx, elem in \"\\(idx): \\(elem)\" }"),
            Example("list.enumerated().map { $0 + $1 }"),
            Example("list.enumerated().something().map { _, elem in elem }")
        ],
        triggeringExamples: [
            Example("for (↓_, foo) in bar.enumerated() { }"),
            Example("for (↓_, foo) in abc.bar.enumerated() { }"),
            Example("for (↓_, foo) in abc.something().enumerated() { }"),
            Example("for (idx, ↓_) in bar.enumerated() { }"),
            Example("list.enumerated().map { idx, ↓_ in idx }"),
            Example("list.enumerated().map { ↓_, elem in elem }"),
            Example("list.enumerated().forEach { print(↓$0) }"),
            Example("list.enumerated().map { ↓$1 }")
        ]
    )
}

private extension UnusedEnumeratedRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private var lookForClosureExpressionSyntax = false
        private var zeroPosition: AbsolutePosition?
        private var onePosition: AbsolutePosition?

        override func visitPost(_ node: ForStmtSyntax) {
            guard let tuplePattern = node.pattern.as(TuplePatternSyntax.self),
                  tuplePattern.elements.count == 2,
                  let functionCall = node.sequence.asFunctionCall,
                  functionCall.isEnumerated,
                  let firstElement = tuplePattern.elements.first,
                  let secondElement = tuplePattern.elements.last,
                  case let firstTokenIsUnderscore = firstElement.isUnderscore,
                  case let lastTokenIsUnderscore = secondElement.isUnderscore,
                  firstTokenIsUnderscore || lastTokenIsUnderscore else {
                return
            }

            addViolation(
                zeroPosition: firstTokenIsUnderscore ? firstElement.positionAfterSkippingLeadingTrivia : nil,
                onePosition: firstTokenIsUnderscore ? nil : secondElement.positionAfterSkippingLeadingTrivia
            )
        }

        override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
            guard node.isEnumerated,
                  let trailingClosure = node.parent?.parent?.as(FunctionCallExprSyntax.self)?.trailingClosure
            else {
                return .visitChildren
            }

            if let parameterClause = trailingClosure.signature?.parameterClause {
                guard let parameterClause = parameterClause.as(ClosureShorthandParameterListSyntax.self),
                      parameterClause.count == 2,
                      let firstElement = parameterClause.firstParameter,
                      let secondElement = parameterClause.lastParameter,
                      case let firstTokenIsUnderscore = firstElement.isUnderscore,
                      case let lastTokenIsUnderscore = secondElement.isUnderscore,
                      firstTokenIsUnderscore || lastTokenIsUnderscore
                else {
                    return .visitChildren
                }

                addViolation(
                    zeroPosition: firstTokenIsUnderscore ? firstElement.positionAfterSkippingLeadingTrivia : nil,
                    onePosition: firstTokenIsUnderscore ? nil : secondElement.positionAfterSkippingLeadingTrivia
                )
            } else {
                lookForClosureExpressionSyntax = true
            }

            return .visitChildren
        }

        override func visitPost(_ node: ClosureExprSyntax) {
            guard lookForClosureExpressionSyntax else {
                return
            }
            defer {
                lookForClosureExpressionSyntax = false
                zeroPosition = nil
                onePosition = nil
            }
            guard (zeroPosition != nil) != (onePosition != nil) else {
                return
            }

            // TODO: If there are references to neither, is that a violation?
            addViolation(zeroPosition: zeroPosition, onePosition: onePosition)
        }

        override func visitPost(_ node: DeclReferenceExprSyntax) {
            guard lookForClosureExpressionSyntax else {
                return
            }
            if node.baseName.text == "$0" {
                zeroPosition = node.positionAfterSkippingLeadingTrivia
            } else if node.baseName.text == "$1" {
                onePosition = node.positionAfterSkippingLeadingTrivia
            }
        }

        private func addViolation(zeroPosition: AbsolutePosition?, onePosition: AbsolutePosition?) {
            var position: AbsolutePosition?
            var reason: String?
            if let zeroPosition {
                position = zeroPosition
                reason = "When the index is not used, `.enumerated()` can be removed"
            } else if let onePosition {
                position = onePosition
                reason = "When the item is not used, `.indices` should be used instead of `.enumerated()`"
            }
            if let position, let reason {
                violations.append(ReasonedRuleViolation(position: position, reason: reason))
            }
        }
    }
}

private extension FunctionCallExprSyntax {
    var isEnumerated: Bool {
        guard let memberAccess = calledExpression.as(MemberAccessExprSyntax.self),
              memberAccess.base != nil,
              memberAccess.declName.baseName.text == "enumerated",
              hasNoArguments else {
            return false
        }

        return true
    }

    var hasNoArguments: Bool {
           trailingClosure == nil
        && additionalTrailingClosures.isEmpty
        && arguments.isEmpty
    }
}

private extension TuplePatternElementSyntax {
    var isUnderscore: Bool {
        pattern.is(WildcardPatternSyntax.self)
    }
}

private extension ClosureShorthandParameterSyntax {
    var isUnderscore: Bool {
        name.tokenKind == .wildcard
    }
}

private extension ClosureShorthandParameterListSyntax {
    var firstParameter: ClosureShorthandParameterSyntax? {
        children(viewMode: .sourceAccurate).first?.as(ClosureShorthandParameterSyntax.self)
    }

    var lastParameter: ClosureShorthandParameterSyntax? {
        children(viewMode: .sourceAccurate).last?.as(ClosureShorthandParameterSyntax.self)
    }
}
