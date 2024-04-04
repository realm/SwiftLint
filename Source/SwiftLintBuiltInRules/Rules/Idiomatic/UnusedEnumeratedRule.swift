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
            Example("list.enumerated().something().map { _, elem in elem }"),
            Example("list.map { ($0.offset, $0.element) }"),
            Example("""
            list.enumerated().map {
                $1.enumerated().forEach { print($0, $1) }
                return $0
            }
            """)
        ],
        triggeringExamples: [
            Example("for (↓_, foo) in bar.enumerated() { }"),
            Example("for (↓_, foo) in abc.bar.enumerated() { }"),
            Example("for (↓_, foo) in abc.something().enumerated() { }"),
            Example("for (idx, ↓_) in bar.enumerated() { }"),
            Example("list.enumerated().map { idx, ↓_ in idx }"),
            Example("list.enumerated().map { ↓_, elem in elem }"),
            Example("list.enumerated().forEach { print(↓$0) }"),
            Example("list.enumerated().map { ↓$1 }"),
            Example("""
            list.enumerated().map {
                $1.enumerated().forEach { print(↓$1) }
                return $0
            }
            """),
            Example("""
            list.enumerated().map {
                ↓$1.enumerated().forEach { print($0, $1) }
                return 1
            }
            """),
            Example("""
            list.enumerated().map {
                list.enumerated().forEach { print($0, $1) }
                return ↓$0
            }
            """),
            Example("""
            list.enumerated().map {
                $1.enumerated().forEach {
                    print($0, $1)
                     $1.enumerated().forEach {
                         print(↓$1)
                     }
                }
                return $0
            }
            """),
            Example("""
            list.enumerated().map {
                $1.enumerated().filter {
                    print($0, $1)
                    $1.enumerated().forEach {
                         if ↓$1 == 2 {
                             return true
                         }
                    }
                    return false
                }
                return $0
            }
            """)
        ]
    )
}

private extension UnusedEnumeratedRule {
    private struct Closure {
        var closure: ClosureExprSyntax
        var zeroPosition: AbsolutePosition?
        var onePosition: AbsolutePosition?
    }

    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private var nextClosure: ClosureExprSyntax?
        private var closures: [Closure] = []

        override func visitPost(_ node: ForStmtSyntax) {
            guard let tuplePattern = node.pattern.as(TuplePatternSyntax.self),
                  tuplePattern.elements.count == 2,
                  let functionCall = node.sequence.asFunctionCall,
                  functionCall.isEnumerated,
                  let firstElement = tuplePattern.elements.first,
                  let secondElement = tuplePattern.elements.last
            else {
                return
            }

            let firstTokenIsUnderscore = firstElement.isUnderscore
            let lastTokenIsUnderscore = secondElement.isUnderscore
            guard firstTokenIsUnderscore || lastTokenIsUnderscore else {
                return
            }

            addViolation(
                zeroPosition: firstTokenIsUnderscore ? firstElement.positionAfterSkippingLeadingTrivia : nil,
                onePosition: firstTokenIsUnderscore ? nil : secondElement.positionAfterSkippingLeadingTrivia
            )
        }

        override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
            guard node.isEnumerated,
                  let parent = node.parent,
                  parent.as(MemberAccessExprSyntax.self)?.declName.baseName.text != "filter",
                  let trailingClosure = parent.parent?.as(FunctionCallExprSyntax.self)?.trailingClosure
            else {
                return .visitChildren
            }

            if let parameterClause = trailingClosure.signature?.parameterClause {
                guard let parameterClause = parameterClause.as(ClosureShorthandParameterListSyntax.self),
                      parameterClause.count == 2,
                      let firstElement = parameterClause.first,
                      let secondElement = parameterClause.last
                else {
                    return .visitChildren
                }

                let firstTokenIsUnderscore = firstElement.isUnderscore
                let lastTokenIsUnderscore = secondElement.isUnderscore
                guard firstTokenIsUnderscore || lastTokenIsUnderscore else {
                    return .visitChildren
                }

                addViolation(
                    zeroPosition: firstTokenIsUnderscore ? firstElement.positionAfterSkippingLeadingTrivia : nil,
                    onePosition: firstTokenIsUnderscore ? nil : secondElement.positionAfterSkippingLeadingTrivia
                )
            } else {
                nextClosure = trailingClosure
            }

            return .visitChildren
        }

        override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
            if node == nextClosure {
                closures.append(Closure(closure: node))
                nextClosure = nil
            }
            return .visitChildren
        }

        override func visitPost(_ node: ClosureExprSyntax) {
            guard let closure = closures.last, node == closure.closure else {
                return
            }
            defer { closures.removeLast() }

            guard (closure.zeroPosition != nil) != (closure.onePosition != nil) else {
                return
            }

            addViolation(zeroPosition: closure.zeroPosition, onePosition: closure.onePosition)
        }

        override func visitPost(_ node: DeclReferenceExprSyntax) {
            guard var closure = closures.last, node.baseName.text == "$0" || node.baseName.text == "$1" else {
                return
            }
            if node.baseName.text == "$0" {
                if node.parent?.as(MemberAccessExprSyntax.self)?.declName.baseName.text == "element" {
                    closure.onePosition = node.positionAfterSkippingLeadingTrivia
                } else {
                    closure.zeroPosition = node.positionAfterSkippingLeadingTrivia
                }
            } else {
                closure.onePosition = node.positionAfterSkippingLeadingTrivia
            }
            closures[closures.count - 1] = closure
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
