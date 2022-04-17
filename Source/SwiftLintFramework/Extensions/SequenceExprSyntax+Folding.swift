// swiftlint:disable all
// Extracted from https://github.com/apple/swift-format/blob/f327c649efbcd7c43c2170f5c2bc7ff360f2e99b/Sources/SwiftFormatPrettyPrint/SequenceExprFolding.swift

//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftSyntax

extension SequenceExprSyntax {

    /// Returns a transformed version of the `SequenceExprSyntax` such that its
    /// shape is tree-like based on the precedence and associativity of the
    /// operators used therein.
    ///
    /// Once folded, the returned expression will have one of three possible
    /// shapes:
    ///
    /// - A subtype of `ExprSyntax` other than `SequenceExprSyntax`
    /// - A `SequenceExprSyntax` with exactly two elements, where the first is an
    ///   operand (a subtype of `ExprSyntax`) and the second is a cast expression
    ///   (either `AsExprSyntax` or `IsExprSyntax`)
    /// - A `SequenceExprSyntax` with exactly three elements, where the first and
    ///   third elements are operands (subtypes of `ExprSyntax`) and the second is
    ///   a `BinaryOperatorExprSyntax`
    ///
    /// The folding operation only applies to the elements in the `SequenceExpr`
    /// on which this method is directly called. It does *not* recursively
    /// traverse the syntax tree (e.g., through function calls or even
    /// parenthesized expressions) to apply the folding operation throughout the
    /// entire tree.
    func folded(context: OperatorContext) -> ExprSyntax {
        // TODO: Look at adding true structural nodes (like BinaryExpr) to
        // SwiftSyntax that would be used to represent the result of folding so that
        // we don't have to distinguish between "shapes" of SequenceExpr.
        guard mayChangeByFolding else { return ExprSyntax(self) }

        let normalizedElements = elements.reduce(into: []) { result, expr in
            normalizeExpression(expr, into: &result)
        }

        assert(
            normalizedElements.count > 1,
            "inadequate number of elements in sequence")
        assert(
            (normalizedElements.count & 1) == 1,
            "even number of elements in sequence")

        let lhs = normalizedElements[0]
        var rest = normalizedElements[1...]
        let result = foldSequence(
            lhs: lhs,
            rest: &rest,
            context: context,
            shouldConsider: { _, _ in true })

        assert(rest.isEmpty)

        return result
    }

    /// Returns true if the sequence expression has a structure that may change if
    /// it is folded.
    ///
    /// This check allows us to short-circuit the folding algorithm in cases where
    /// we know we would get the same output as our input. This is helpful
    /// because, unlike the Swift compiler, SwiftSyntax doesn't have a separate
    /// node type for things like binary expressions or assignment expressions
    /// (well, it does, but they contain *only* the operator), so we can only fold
    /// such sequence expressions back into sequence expressions with fixed shapes
    /// (e.g., a binary expression is three-element sequence `(lhs, op, rhs)`).
    /// Therefore, instead of trying to track whether or not a particular sequence
    /// *has been* folded, it's cleaner to ask for it to be folded unconditionally
    /// and return the original if we know it doesn't *need* to be folded.
    private var mayChangeByFolding: Bool {
        switch elements.count {
        case 1:
            // A sequence with one element will not be changed by folding unless that
            // element is a ternary expression.
            return elements.first!.is(TernaryExprSyntax.self)

        case 2:
            // A sequence with two elements might be changed by folding if the first
            // element is a ternary or the second element is something other than a
            // cast.
            var elementsIterator = elements.makeIterator()
            let first = elementsIterator.next()!
            let second = elementsIterator.next()!
            return first.is(TernaryExprSyntax.self)
            || !(second.is(AsExprSyntax.self) || second.is(IsExprSyntax.self))

        case 3:
            // A sequence with three elements will not be changed by folding unless
            // it contains a cast expression, ternary, `await`, or `try`. (This may
            // be more inclusive than it needs to be.)
            return elements.contains {
                $0.is(AsExprSyntax.self) || $0.is(IsExprSyntax.self)
                || $0.is(TernaryExprSyntax.self) || $0.is(AwaitExprSyntax.self)
                || $0.is(TryExprSyntax.self)
            }

        default:
            // A sequence with more than three elements will be changed by folding.
            return true
        }
    }

    /// Folds a sequence expression with the given left-hand side and remaining
    /// elements.
    ///
    /// This method may be called recursively.
    ///
    /// - Parameters:
    ///   - lhs: The left-hand side of the expression.
    ///   - rest: The remaining elements of the sequence being folded. This slice
    ///     will be modified (elements dropped from the front) by this function.
    ///   - context: The context that defines the operators and precedence groups.
    ///   - shouldConsider: A predicate that takes an optional precedence group
    ///     and the operator context and returns a value indicating whether the
    ///     operator should be considered as part of the current expression.
    /// - Returns: The folded expression.
    private func foldSequence(
        lhs: ExprSyntax,
        rest: inout ArraySlice<ExprSyntax>,
        context: OperatorContext,
        shouldConsider: @escaping (PrecedenceGroup?, OperatorContext) -> Bool
    ) -> ExprSyntax {
        // Invariants:
        //   - `rest` has even count.
        //   - All elements at even indices are operator references.
        precondition(!rest.isEmpty)
        precondition((rest.count & 1) == 0)

        var lhs = lhs

        // Extract the first operator.
        guard var op1 = peekNextOperator(
            in: rest, context: context, shouldConsider: shouldConsider)
        else {
            return lhs
        }

        // We will definitely be consuming at least one operator. Pull out the
        // prospective RHS and slice off the first two elements.
        var rhs = rhsExpr(extractedFrom: &rest)

        while !rest.isEmpty {
            assert((rest.count & 1) == 0)
            assert(shouldConsider(op1.precedenceGroup, context))

            // If the operator is a cast operator, the RHS can't extend past the type
            // that's part of the cast production.
            if op1.operatorExpr.is(AsExprSyntax.self) || op1.operatorExpr.is(IsExprSyntax.self) {
                lhs = makeExpression(
                    operator: op1.operatorExpr, lhs: lhs, rhs: rhs, context: context)

                guard let maybeOp = peekNextOperator(
                    in: rest, context: context, shouldConsider: shouldConsider)
                else {
                    return lhs
                }
                op1 = maybeOp
                rhs = rhsExpr(extractedFrom: &rest)
                continue
            }

            // Pull out the next binary operator.
            let op2Expr = rest.first!
            let op2 = OperatorAndPrecedence(
                operatorExpr: op2Expr,
                precedenceGroup:
                    precedenceGroup(forInfixOperator: op2Expr, context: context))

            // If the second operator's precedence is lower than the precedence bound,
            // break out of the loop.
            guard shouldConsider(op2.precedenceGroup, context) else { break }

            // If we're missing precedence info for either operator, treat them as
            // non-associative.
            let associativity: Associativity?
            if let op1Precedence = op1.precedenceGroup,
               let op2Precedence = op2.precedenceGroup
            {
                associativity =
                context.associativityBetween(op1Precedence, op2Precedence)
            } else {
                associativity = nil
            }

            // Apply left-associativity immediately by folding the first two operands.
            if associativity == .left {
                lhs = makeExpression(
                    operator: op1.operatorExpr, lhs: lhs, rhs: rhs, context: context)
                op1 = op2

                rhs = rhsExpr(extractedFrom: &rest)
                continue
            }

            // If the first operator's precedence is lower than the second operator's
            // precedence, recursively fold all such higher-precedence operators
            // starting from this point, then repeat.
            if associativity == .right
                && op1.precedenceGroup !== op2.precedenceGroup
            {
                rhs = foldSequence(
                    lhs: rhs,
                    rest: &rest,
                    context: context,
                    shouldConsider: PrecedenceBound(
                        precedenceGroup: op1.precedenceGroup, isStrict: true).shouldConsider
                )
                continue
            }

            // Apply right-associativity by recursively folding operators starting
            // from this point, then immediately folding the LHS and RHS.
            if associativity == .right {
                rhs = foldSequence(
                    lhs: rhs,
                    rest: &rest,
                    context: context,
                    shouldConsider: PrecedenceBound(
                        precedenceGroup: op1.precedenceGroup, isStrict: false)
                    .shouldConsider)
                lhs = makeExpression(
                    operator: op1.operatorExpr, lhs: lhs, rhs: rhs, context: context)

                // If we've drained the entire sequence, we're done.
                if rest.isEmpty { return lhs }

                // Otherwise, start all over with our new LHS.
                return foldSequence(
                    lhs: lhs,
                    rest: &rest,
                    context: context,
                    shouldConsider: shouldConsider)
            }

            // If we ended up here, it's because we're either:
            //   - missing precedence groups,
            //   - have unordered precedence groups, or
            //   - have the same precedence group with no associativity.
            assert(associativity == .none)

            // Recover by arbitrarily binding the first two.
            lhs = makeExpression(
                operator: op1.operatorExpr, lhs: lhs, rhs: rhs, context: context)
            return foldSequence(
                lhs: lhs,
                rest: &rest,
                context: context,
                shouldConsider: shouldConsider)
        }

        // Fold LHS and RHS together and declare completion.
        return makeExpression(
            operator: op1.operatorExpr, lhs: lhs, rhs: rhs, context: context)
    }

    /// Normalizes an element of a sequence expression so that it has the same
    /// layout as the one that would have been produced by the compiler and adds
    /// the resulting element or elements to the end of the given array.
    private func normalizeExpression(
        _ expr: ExprSyntax,
        into elements: inout [ExprSyntax]
    ) {
        // In order to simplify implementation, we construct a new elements array
        // that has the same layout as the one that would have been produced by the
        // compiler; see
        // <https://github.com/apple/swift/blob/d6c92dcfca5b81dc7433b8c5efc9513461598894/lib/Sema/TypeCheckExpr.cpp#L729-L741>.
        // This layout differs from the syntax tree that SwiftSyntax emits in a
        // couple subtle ways that are described below.
        if expr.is(AsExprSyntax.self) || expr.is(IsExprSyntax.self) {
            // Cast operators (`as`, `is`) appear twice in the list to preserve the
            // even/odd property of the rest of the sequence; that is, that each
            // even-indexed element is an operand and each odd-indexed element is
            // (or begins with) an operator.
            elements.append(expr)
            elements.append(expr)
        } else if let ternaryExpr = expr.as(TernaryExprSyntax.self) {
            // In the compiler implementation, ternary expressions have their
            // condition and false choice appear in the main sequence, with the true
            // choice nested inside an `if-expr` with null values for the other two
            // parts. In order to match that behavior, we extract the condition and
            // false choice from the ternary and put them directly in the sequence.
            // We can't null out those properties of a `TernaryExprSyntax` because
            // they are non-optional, so instead we simply insert the original
            // ternary in that slot and the rest of the algorithm will ignore
            // everything except for the true choice.
            normalizeExpression(ternaryExpr.conditionExpression, into: &elements)
            elements.append(ExprSyntax(ternaryExpr))
            normalizeExpression(ternaryExpr.secondChoice, into: &elements)
        } else {
            elements.append(expr)
        }
    }

    /// Returns the precedence group for the infix operator corresponding to the
    /// given `ExprSyntax` in a sequence, or nil if the operator does not exist.
    private func precedenceGroup(
        forInfixOperator infixOp: ExprSyntax,
        context: OperatorContext
    ) -> PrecedenceGroup? {
        switch Syntax(infixOp).as(SyntaxEnum.self) {
        case .arrowExpr:
            return context.precedenceGroup(named: .functionArrow)
        case .asExpr, .isExpr:
            return context.precedenceGroup(named: .casting)
        case .assignmentExpr:
            return context.precedenceGroup(named: .assignment)
        case .binaryOperatorExpr(let binOpExpr):
            let infixOpName = binOpExpr.operatorToken.text
            return context.infixOperator(named: infixOpName)?.precedenceGroup
        case .ternaryExpr:
            return context.precedenceGroup(named: .ternary)
        default:
            // This branch will cover any potential new nodes that might arise in the
            // future to represent other kinds of infix operators in a sequence.
            return nil
        }
    }

    /// Returns a new expression that combines the given operator with potential
    /// left-hand and right-hand sides.
    ///
    /// This function takes into account certain corrections that must occur as
    /// part of folding, like repairing ternary and cast expressions (undoing the
    /// even/odd normalization that was performed at the beginning of the
    /// algorithm), as well as absorbing other operators and operands into
    /// `await/try` expressions.
    private func makeExpression(
        operator op: ExprSyntax,
        lhs: ExprSyntax,
        rhs: ExprSyntax,
        context: OperatorContext
    ) -> ExprSyntax {
        var lhs = lhs

        // If the left-hand side is a `try` or `await`, hoist it up. The compiler
        // will parse an expression like `try|await foo() + 1` syntactically as
        // `SequenceExpr(TryExpr|AwaitExpr(foo()), +, 1)`, then fold the rest of
        // the expression into the `try|await` as
        // `TryExpr|AwaitExpr(BinaryExpr(foo(), +, 1))`. So, we temporarily drop
        // down to the subexpression for the purposes of this function, then before
        // returning below, we wrap the result back in the `try|await`.
        //
        // If the right-hand side is a `try` or `await`, it's an error unless the
        // operator is an assignment or ternary operator and there's nothing to the
        // right that didn't parse as part of the right operand. The compiler
        // handles that case so that it can emit an error, but for the purposes of
        // the syntax tree, we can leave it alone.
        let maybeTryExpr = lhs.as(TryExprSyntax.self)
        if let tryExpr = maybeTryExpr {
            lhs = tryExpr.expression
        }
        let maybeAwaitExpr = lhs.as(AwaitExprSyntax.self)
        if let awaitExpr = maybeAwaitExpr {
            lhs = awaitExpr.expression
        }

        let makeResultExpression = { (expr: ExprSyntax) -> ExprSyntax in
            // Fold the result back into the `try` and/or `await` if either were
            // present; otherwise, just return the result itself.
            var result = expr
            if let awaitExpr = maybeAwaitExpr {
                result = ExprSyntax(awaitExpr.withExpression(result))
            }
            if let tryExpr = maybeTryExpr {
                result = ExprSyntax(tryExpr.withExpression(result))
            }
            return result
        }

        switch Syntax(op).as(SyntaxEnum.self) {
        case .ternaryExpr(let ternaryExpr):
            // Resolve the ternary expression by pulling the LHS and RHS that we
            // actually want into it.

            let result = ternaryExpr
                .withConditionExpression(lhs)
                .withSecondChoice(rhs)
            return makeResultExpression(ExprSyntax(result))
        case .asExpr, .isExpr:
            // A normalized cast expression will have a regular LHS, then `as/is Type`
            // as the operator *and* the RHS. We resolve it by returning a new
            // sequence expression that discards the extra RHS.
            let result = SyntaxFactory.makeSequenceExpr(
                elements: SyntaxFactory.makeExprList([lhs, op]))
            return makeResultExpression(ExprSyntax(result))
        default:
            // For any other binary operator, we simply return a sequence that has the
            // three elements.
            let result = SyntaxFactory.makeSequenceExpr(
                elements: SyntaxFactory.makeExprList([lhs, op, rhs]))
            return makeResultExpression(ExprSyntax(result))
        }
    }

    /// Returns the next operator in the given slice if it has a precedence that
    /// the predicate deems should be considered.
    ///
    /// This method peeks at the first element of the slice but does *not* remove
    /// it.
    ///
    /// - Precondition: `rest` must not be empty and its first element must be an
    ///   infix operator.
    ///
    /// - Parameters:
    ///   - rest: The remaining elements of the sequence to be folded.
    ///   - context: The context that defines the operators and precedence groups.
    ///   - shouldConsider: A predicate that takes an optional precedence group
    ///     and the operator context and returns a value indicating whether the
    ///     operator should be considered as part of the current expression.
    /// - Returns: If the
    private func peekNextOperator(
        in rest: ArraySlice<ExprSyntax>,
        context: OperatorContext,
        shouldConsider: @escaping (PrecedenceGroup?, OperatorContext) -> Bool
    ) -> OperatorAndPrecedence? {
        guard let op = rest.first else {
            preconditionFailure("slice should not be empty")
        }

        // If the operator's precedence is lower than the minimum, stop here.
        let opPrecedence = precedenceGroup(forInfixOperator: op, context: context)
        guard shouldConsider(opPrecedence, context) else { return nil }

        return OperatorAndPrecedence(
            operatorExpr: op, precedenceGroup: opPrecedence)
    }

    /// Given a slice of a sequence expression starting with an operator
    /// expression, this method extracts the first element of its right-hand side
    /// (the element immediately following that operator), removes the operator
    /// and RHS from the slice, and returns the RHS.
    private func rhsExpr(extractedFrom rest: inout ArraySlice<ExprSyntax>)
    -> ExprSyntax
    {
        let rhs = rest[rest.index(after: rest.startIndex)]
        rest = rest.dropFirst(2)
        return rhs
    }
}

/// A pair consisting of an infix operator expression and its precedence group.
fileprivate struct OperatorAndPrecedence {

    /// The infix operator expression.
    let operatorExpr: ExprSyntax

    /// The precedence group of `operatorExpr`, or nil if the precedence is not
    /// known.
    let precedenceGroup: PrecedenceGroup?
}

/// Encapsulates a precedence group and strictness value for consideration
/// during folding.
fileprivate struct PrecedenceBound {

    /// The precedence group against which the one passed to the predicate will be
    /// compared.
    private let precedenceGroup: PrecedenceGroup?

    /// Indicates whether the bound is strict, meaning that two operators with the
    /// same precedence should not be considered.
    private let isStrict: Bool

    /// Creates a new bound with the given precedence group and strictness.
    init(precedenceGroup: PrecedenceGroup?, isStrict: Bool) {
        self.precedenceGroup = precedenceGroup
        self.isStrict = isStrict
    }

    /// Returns a value indicating whether an operator whose precedence is `group`
    /// should be considered against operators with the stored precedence and
    /// strictness.
    func shouldConsider(
        group: PrecedenceGroup?,
        context: OperatorContext
    ) -> Bool {
        guard let storedGroup = precedenceGroup else { return true }
        guard let group = group else { return false }
        if storedGroup === group { return !isStrict }
        return context.associativityBetween(group, storedGroup) != .right
    }
}
