import Foundation
import SourceKittenFramework
import SwiftLintCore
import SwiftSyntax

struct MultilineFunctionChainsRule: SourceKitFreeRule, OptInRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "multiline_function_chains",
        name: "Multiline Function Chains",
        description: "Chained function calls should be either on the same line, or one per line",
        kind: .style,
        nonTriggeringExamples: #examples([
            "let evenSquaresSum = [20, 17, 35, 4].filter { $0 % 2 == 0 }.map { $0 * $0 }.reduce(0, +)",
            """
            let evenSquaresSum = [20, 17, 35, 4]
                .filter { $0 % 2 == 0 }.map { $0 * $0 }.reduce(0, +)",
            """,
            """
            let chain = a
                .b(1, 2, 3)
                .c { blah in
                    print(blah)
                }
                .d()
            """,
            """
            let chain = a.b(1, 2, 3)
                .c { blah in
                    print(blah)
                }
                .d()
            """,
            """
            let chain = a.b(1, 2, 3)
                .c { blah in print(blah) }
                .d()
            """,
            """
            let chain = a.b(1, 2, 3)
                .c(.init(
                    a: 1,
                    b, 2,
                    c, 3))
                .d()
            """,
            """
            self.viewModel.outputs.postContextualNotification
              .observeForUI()
              .observeValues {
                NotificationCenter.default.post(
                  Notification(
                    name: .ksr_showNotificationsDialog,
                    userInfo: [UserInfoKeys.context: PushNotificationDialog.Context.pledge,
                               UserInfoKeys.viewController: self]
                 )
                )
              }
            """,
            "let remainingIDs = Array(Set(self.currentIDs).subtracting(Set(response.ids)))",
            """
            self.happeningNewsletterOn = self.updateCurrentUser
                .map { $0.newsletters.happening }.skipNil().skipRepeats()
            """,
        ]),
        triggeringExamples: #examples([
            """
            let evenSquaresSum = [20, 17, 35, 4]
                .filter { $0 % 2 == 0 }↓.map { $0 * $0 }
                .reduce(0, +)
            """,
            """
            let evenSquaresSum = a.b(1, 2, 3)
                .c { blah in
                    print(blah)
                }↓.d()
            """,
            """
            let evenSquaresSum = a.b(1, 2, 3)
                .c(2, 3, 4)↓.d()
            """,
            """
            let evenSquaresSum = a.b(1, 2, 3)↓.c { blah in
                    print(blah)
                }
                .d()
            """,
            """
            a.b {
            //  ““
            }↓.e()
            """,
        ])
    )

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        ChainVisitor(viewMode: .sourceAccurate)
            .walk(file: file, handler: \.callRangeGroups)
            .flatMap { violatingOffsets(file: file, callRanges: $0) }
            .map { offset in
                StyleViolation(ruleDescription: Self.description,
                               severity: configuration.severity,
                               location: Location(file: file, characterOffset: offset))
            }
    }

    private func violatingOffsets(file: SwiftLintFile, callRanges: [ByteRange]) -> [Int] {
        let calls = callRanges.compactMap { range -> (dotLine: Int, dotOffset: Int, range: ByteRange)? in
            guard let offset = callDotOffset(file: file, callRange: range),
                  let line = file.stringView.lineAndCharacter(forCharacterOffset: offset)?.line else {
                return nil
            }
            return (dotLine: line, dotOffset: offset, range: range)
        }

        let uniqueLines = calls.map(\.dotLine).unique

        if uniqueLines.count == 1 { return [] }

        // The first call (last here) is allowed to not have a leading newline.
        let noLeadingNewlineViolations = calls
            .dropLast()
            .filter { line in
                !callHasLeadingNewline(file: file, callRange: line.range)
            }

        return noLeadingNewlineViolations.map(\.dotOffset)
    }

    private static let whitespaceDotRegex = regex("\\s*\\.")

    private func callDotOffset(file: SwiftLintFile, callRange: ByteRange) -> Int? {
        guard let range = file.stringView.byteRangeToNSRange(callRange),
              case let regex = Self.whitespaceDotRegex,
              let match = regex.matches(in: file.contents, options: [], range: range).last?.range else {
            return nil
        }
        return match.location + match.length - 1
    }

    private static let newlineWhitespaceDotRegex = regex("\\n\\s*\\.")

    private func callHasLeadingNewline(file: SwiftLintFile, callRange: ByteRange) -> Bool {
        guard let range = file.stringView.byteRangeToNSRange(callRange),
              case let regex = Self.newlineWhitespaceDotRegex,
              regex.firstMatch(in: file.contents, options: [], range: range) != nil else {
            return false
        }
        return true
    }
}

private extension MultilineFunctionChainsRule {
    /// Collects, for every call expression, the byte ranges of its chain links. The ranges mirror the ones
    /// this rule used to derive from SourceKit's `expr.call` structure: for every link, the bytes from the
    /// end of the subcall's body to the end of the parent call's name, and for the innermost call of a
    /// chain, its name range.
    final class ChainVisitor: SyntaxVisitor {
        private(set) var callRangeGroups = [[ByteRange]]()

        override func visit(_ node: IfConfigClauseSyntax) -> SyntaxVisitorContinueKind {
            // SourceKit reports the structure of the first clause of a postfix `#if` expression only.
            node.isSkippedPostfixIfConfigClause ? .skipChildren : .visitChildren
        }

        override func visitPost(_ node: FunctionCallExprSyntax) {
            appendCallRanges(of: ExprSyntax(node))
        }

        override func visitPost(_ node: SubscriptCallExprSyntax) {
            appendCallRanges(of: ExprSyntax(node))
        }

        private func appendCallRanges(of node: ExprSyntax) {
            let ranges = callRanges(of: node, isSubcall: false)
            if ranges.isNotEmpty {
                callRangeGroups.append(ranges)
            }
        }

        private func callRanges(of node: ExprSyntax, isSubcall: Bool) -> [ByteRange] {
            guard let callee = node.calleeExpression else {
                return []
            }

            let (subcall, searchScopes) = callee.chainedSubcall

            guard let subcall else {
                // Like in SourceKit's structure, a call is only the innermost link of a chain if it
                // contains no other call that isn't wrapped in an argument, closure, collection, etc.
                if isSubcall, !searchScopes.contains(where: { Syntax($0).containsDirectSubcall }) {
                    let name = byteRange(from: callee.positionAfterSkippingLeadingTrivia,
                                         to: callee.endPositionBeforeTrailingTrivia)
                    return [name]
                }
                return []
            }

            guard let subcallBodyEnd = subcall.callBodyEndPosition else {
                return []
            }

            let link = byteRange(from: subcallBodyEnd, to: callee.endPositionBeforeTrailingTrivia)
            return [link] + callRanges(of: subcall, isSubcall: true)
        }

        private func byteRange(from start: AbsolutePosition, to end: AbsolutePosition) -> ByteRange {
            ByteRange(location: ByteCount(start.utf8Offset),
                      length: ByteCount(end.utf8Offset - start.utf8Offset))
        }
    }
}

private extension ExprSyntax {
    /// The expression a call or subscript is performed on, matching the name range of SourceKit's
    /// `expr.call` structure nodes.
    var calleeExpression: ExprSyntax? {
        if let call = `as`(FunctionCallExprSyntax.self) {
            return call.calledExpression
        }
        if let subscriptCall = `as`(SubscriptCallExprSyntax.self) {
            return subscriptCall.calledExpression
        }
        return nil
    }

    /// The position after a call's body, that is the position of its closing parenthesis, bracket or
    /// trailing closure brace, matching the end of the body range SourceKit reports for `expr.call`.
    var callBodyEndPosition: AbsolutePosition? {
        if let call = `as`(FunctionCallExprSyntax.self) {
            guard call.rightParen != nil || call.trailingClosure != nil else {
                return nil
            }
            return call.lastToken(viewMode: .sourceAccurate)?.positionAfterSkippingLeadingTrivia
        }
        if let subscriptCall = `as`(SubscriptCallExprSyntax.self) {
            return subscriptCall.lastToken(viewMode: .sourceAccurate)?.positionAfterSkippingLeadingTrivia
        }
        return nil
    }

    /// Walks down the leftmost postfix chain of a callee to the nested call the chain continues from,
    /// mirroring how SourceKit nests the `expr.call` structures of a chain, which all share their name
    /// offset. Also returns the expressions that can contribute direct subcalls when no nested call is
    /// found.
    var chainedSubcall: (subcall: ExprSyntax?, searchScopes: [ExprSyntax]) {
        var searchScopes = [self]
        var expr = self
        while true {
            if expr.calleeExpression != nil {
                return (expr, searchScopes)
            }
            if let member = expr.as(MemberAccessExprSyntax.self) {
                if let base = member.base {
                    expr = base
                } else if let ifConfigBase = member.postfixIfConfigBase {
                    // A member access starting a postfix `#if` clause: SourceKit chains it to the base
                    // of the surrounding `#if` expression.
                    searchScopes.append(ifConfigBase)
                    expr = ifConfigBase
                } else {
                    return (nil, searchScopes)
                }
            } else if let unwrap = expr.as(ForceUnwrapExprSyntax.self) {
                expr = unwrap.expression
            } else if let chaining = expr.as(OptionalChainingExprSyntax.self) {
                expr = chaining.expression
            } else if let postfixOperator = expr.as(PostfixOperatorExprSyntax.self) {
                expr = postfixOperator.expression
            } else if let specialization = expr.as(GenericSpecializationExprSyntax.self) {
                expr = specialization.expression
            } else if let postfixIfConfig = expr.as(PostfixIfConfigExprSyntax.self),
                      case .postfixExpression(let element)? = postfixIfConfig.config.clauses.first?.elements {
                // A chain continuing after `#endif`: SourceKit chains it into the first `#if` clause.
                expr = element
            } else {
                return (nil, searchScopes)
            }
        }
    }
}

private extension Syntax {
    /// Whether SourceKit would report an `expr.call` structure directly in this subtree, that is a call
    /// not wrapped in another structure-producing node like an argument, a closure or a collection.
    var containsDirectSubcall: Bool {
        if let clause = `as`(IfConfigClauseSyntax.self) {
            // SourceKit emits no structure for `#if` conditions and skips all but the first clause of a
            // postfix `#if` expression.
            guard !clause.isSkippedPostfixIfConfigClause, let elements = clause.elements else {
                return false
            }
            return Syntax(elements).containsDirectSubcall
        }
        if let expr = `as`(ExprSyntax.self) {
            if expr.calleeExpression != nil {
                return true
            }
            if let keyPath = expr.as(KeyPathExprSyntax.self) {
                // SourceKit models key path subscript components as call expressions. (Method
                // components would as well, but their syntax case is SPI while the language
                // feature remains experimental.)
                return keyPath.components.contains { component in
                    if case .subscript = component.component {
                        return true
                    }
                    return false
                }
            }
            if let tuple = expr.as(TupleExprSyntax.self) {
                // Parenthesized expressions are transparent in SourceKit's structure, while real tuples
                // produce an `expr.tuple` node wrapping their elements.
                if let onlyElement = tuple.elements.onlyElement {
                    return Syntax(onlyElement.expression).containsDirectSubcall
                }
                return false
            }
            switch expr.kind {
            case .closureExpr, .arrayExpr, .dictionaryExpr, .macroExpansionExpr, .ifExpr, .switchExpr:
                // These produce their own structure nodes wrapping any nested call.
                return false
            default:
                break
            }
        }
        return children(viewMode: .sourceAccurate).contains(where: \.containsDirectSubcall)
    }
}

private extension MemberAccessExprSyntax {
    /// The base of the postfix `#if` expression whose first clause starts with this member access, if
    /// there is one and this member access has no base of its own.
    var postfixIfConfigBase: ExprSyntax? {
        guard base == nil else {
            return nil
        }
        var outermost = Syntax(self)
        while let parent = outermost.parent, parent.is(ExprSyntax.self) {
            outermost = parent
        }
        guard outermost.positionAfterSkippingLeadingTrivia == positionAfterSkippingLeadingTrivia,
              let clause = outermost.parent?.as(IfConfigClauseSyntax.self),
              let ifConfigDecl = clause.parent?.parent?.as(IfConfigDeclSyntax.self),
              let postfixIfConfig = ifConfigDecl.parent?.as(PostfixIfConfigExprSyntax.self) else {
            return nil
        }
        return postfixIfConfig.base
    }
}

private extension IfConfigClauseSyntax {
    /// Whether SourceKit omits this clause from the structure. It only reports the first clause of a
    /// postfix `#if` expression.
    var isSkippedPostfixIfConfigClause: Bool {
        guard let clauseList = parent?.as(IfConfigClauseListSyntax.self),
              clauseList.parent?.parent?.is(PostfixIfConfigExprSyntax.self) == true else {
            return false
        }
        return id != clauseList.first?.id
    }
}
