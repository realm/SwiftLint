import SwiftSyntax

@SwiftSyntaxRule
struct UnusedEnumeratedRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "unused_enumerated",
        name: "Unused Enumerated",
        description: "When the index or the item is not used, `.enumerated()` can be removed.",
        kind: .idiomatic,
        nonTriggeringExamples: #examples([
            "for (idx, foo) in bar.enumerated() { }",
            "for (_, foo) in bar.enumerated().something() { }",
            "for (_, foo) in bar.something() { }",
            "for foo in bar.enumerated() { }",
            "for foo in bar { }",
            "for (idx, _) in bar.enumerated().something() { }",
            "for (idx, _) in bar.something() { }",
            "for idx in bar.indices { }",
            "for (section, (event, _)) in data.enumerated() {}",
            "list.enumerated().map { idx, elem in \"\\(idx): \\(elem)\" }",
            "list.enumerated().map { $0 + $1 }",
            "list.enumerated().something().map { _, elem in elem }",
            "list.enumerated().map { ($0.offset, $0.element) }",
            "list.enumerated().map { ($0.0, $0.1) }",
            """
            list.enumerated().first {
                $0.element.0.isNumber &&
                $0.element.1.isNumber &&
                $0.element.0 != $0.element.1
            }?.offset
            """,
            """
            (list.enumerated().first {
                $0.element.isNumber
            })?.offset
            """,
            """
            list.enumerated().max {
                $0.element < $1.element
            }?.offset
            """,
            """
            list.enumerated().map {
                $1.enumerated().forEach { print($0, $1) }
                return $0
            }
            """,
            """
            list.enumerated().forEach {
                f($0)
                let (i, e) = $0
                print(i)
            }
            """.excludeFromDocumentation(),
        ]),
        triggeringExamples: #examples([
            "for (↓_, foo) in bar.enumerated() { }",
            "for (↓_, foo) in abc.bar.enumerated() { }",
            "for (↓_, foo) in abc.something().enumerated() { }",
            "for (idx, ↓_) in bar.enumerated() { }",
            "list.enumerated().map { idx, ↓_ in idx }",
            "list.enumerated().map { ↓_, elem in elem }",
            "list.↓enumerated().forEach { print($0) }",
            "list.↓enumerated().map { $1 }",
            """
            list.enumerated().map {
                $1.↓enumerated().forEach { print($1) }
                return $0
            }
            """,
            """
            list.↓enumerated().map {
                $1.enumerated().forEach { print($0, $1) }
                return 1
            }
            """,
            """
            list.enumerated().map {
                $1.enumerated().filter {
                    print($0, $1)
                    $1.↓enumerated().forEach {
                         if $1 == 2 {
                             return true
                         }
                    }
                    return false
                }
                return $0
            }
            """.excludeFromDocumentation()
            ,
            """
            list.↓enumerated().map {
                $1.forEach { print($0) }
                return $1
            }
            """.excludeFromDocumentation(),
            """
            list.↓enumerated().forEach {
                let (i, _) = $0
            }
            """,
        ])
    )
}

private extension UnusedEnumeratedRule {
    private struct Closure {
        let enumeratedPosition: AbsolutePosition
        let usedEnumeratedResultMembers: (zero: Bool, one: Bool)
        var zeroPosition: AbsolutePosition?
        var onePosition: AbsolutePosition?
    }

    private struct PendingClosure {
        let id: SyntaxIdentifier
        let enumeratedPosition: AbsolutePosition
        let usedEnumeratedResultMembers: (zero: Bool, one: Bool)
    }

    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private var pendingClosure: PendingClosure?
        private var closures = Stack<Closure?>()

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
                  let parentCall = parent.parent?.as(FunctionCallExprSyntax.self),
                  let trailingClosure = parentCall.trailingClosure
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
            } else if let enumeratedPosition = node.enumeratedPosition {
                pendingClosure = PendingClosure(
                    id: trailingClosure.id,
                    enumeratedPosition: enumeratedPosition,
                    usedEnumeratedResultMembers: ExprSyntax(parentCall).usedEnumeratedResultMembers
                )
            }

            return .visitChildren
        }

        override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
            if let pendingClosure, pendingClosure.id == node.id {
                closures.push(Closure(
                    enumeratedPosition: pendingClosure.enumeratedPosition,
                    usedEnumeratedResultMembers: pendingClosure.usedEnumeratedResultMembers
                ))
                self.pendingClosure = nil
            } else {
                closures.push(nil)
            }
            return .visitChildren
        }

        override func visitPost(_: ClosureExprSyntax) {
            guard let closure = closures.pop().flatMap(\.self) else { return }

            let zeroPosition = closure.zeroPosition
                ?? (closure.usedEnumeratedResultMembers.zero ? closure.enumeratedPosition : nil)
            let onePosition = closure.onePosition
                ?? (closure.usedEnumeratedResultMembers.one ? closure.enumeratedPosition : nil)
            guard (zeroPosition != nil) != (onePosition != nil) else { return }

            addViolation(
                zeroPosition: onePosition,
                onePosition: zeroPosition,
                enumeratedPosition: closure.enumeratedPosition
            )
        }

        override func visitPost(_ node: DeclReferenceExprSyntax) {
            guard
                closures.peek().flatMap(\.self) != nil,
                node.baseName.text == "$0" || node.baseName.text == "$1"
            else {
                return
            }

            closures.modifyLast { trackedClosure in
                guard var closure = trackedClosure else { return }

                if node.baseName.text == "$0" {
                    let member = node.parent?.as(MemberAccessExprSyntax.self)?.declName.baseName.text
                    if member == "element" || member == "1" {
                        closure.onePosition = node.positionAfterSkippingLeadingTrivia
                    } else {
                        closure.zeroPosition = node.positionAfterSkippingLeadingTrivia
                        if node.isUnpacked {
                            closure.onePosition = node.positionAfterSkippingLeadingTrivia
                        }
                    }
                } else {
                    closure.onePosition = node.positionAfterSkippingLeadingTrivia
                }

                trackedClosure = closure
            }
        }

        private func addViolation(
            zeroPosition: AbsolutePosition?,
            onePosition: AbsolutePosition?,
            enumeratedPosition: AbsolutePosition? = nil
        ) {
            var position: AbsolutePosition?
            var reason: String?
            if let zeroPosition {
                position = zeroPosition
                reason = "When the index is not used, `.enumerated()` can be removed"
            } else if let onePosition {
                position = onePosition
                reason = "When the item is not used, `.indices` should be used instead of `.enumerated()`"
            }

            if let enumeratedPosition {
                position = enumeratedPosition
            }

            if let position, let reason {
                violations.append(ReasonedRuleViolation(position: position, reason: reason))
            }
        }
    }
}

private extension FunctionCallExprSyntax {
    var isEnumerated: Bool {
        enumeratedPosition != nil
    }

    var enumeratedPosition: AbsolutePosition? {
        if let memberAccess = calledExpression.as(MemberAccessExprSyntax.self),
           memberAccess.base != nil,
           memberAccess.declName.baseName.text == "enumerated",
           hasNoArguments {
            return memberAccess.declName.positionAfterSkippingLeadingTrivia
        }

        return nil
    }

    var hasNoArguments: Bool {
           trailingClosure == nil
        && additionalTrailingClosures.isEmpty
        && arguments.isEmpty
    }
}

private extension ExprSyntax {
    var usedEnumeratedResultMembers: (zero: Bool, one: Bool) {
        if let tupleElement = parent?.as(LabeledExprSyntax.self),
           tupleElement.expression.id == id,
           let tuple = tupleElement.parent?.parent?.as(TupleExprSyntax.self),
           tuple.elements.onlyElement?.id == tupleElement.id {
            return ExprSyntax(tuple).usedEnumeratedResultMembers
        }

        guard let parent = parent?.as(ExprSyntax.self) else {
            return (false, false)
        }

        if let memberAccess = parent.as(MemberAccessExprSyntax.self),
           memberAccess.base?.id == id {
            switch memberAccess.declName.baseName.text {
            case "offset", "0":
                return (true, false)
            case "element", "1":
                return (false, true)
            default:
                return parent.usedEnumeratedResultMembers
            }
        }

        if parent.as(OptionalChainingExprSyntax.self)?.expression.id == id
           || parent.as(ForceUnwrapExprSyntax.self)?.expression.id == id
           || parent.as(TupleExprSyntax.self)?.elements.onlyElement?.expression.id == id {
            return parent.usedEnumeratedResultMembers
        }

        return (false, false)
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

private extension DeclReferenceExprSyntax {
    var isUnpacked: Bool {
        if let initializer = parent?.as(InitializerClauseSyntax.self),
           let binding = initializer.parent?.as(PatternBindingSyntax.self),
           let elements = binding.pattern.as(TuplePatternSyntax.self)?.elements {
            return elements.count == 2 && elements.allSatisfy { !$0.pattern.is(WildcardPatternSyntax.self) }
        }
        return false
    }
}
