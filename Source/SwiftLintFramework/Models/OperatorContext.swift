// swiftlint:disable all
// Extracted from https://github.com/apple/swift-format/blob/f327c649efbcd7c43c2170f5c2bc7ff360f2e99b/Sources/SwiftFormatPrettyPrint/OperatorContext.swift

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

/// Contains information about precedence groups and operators used when folding
/// sequence expressions.
internal final class OperatorContext {

    /// The key used to store the associativity between two precedence groups in
    /// the cache.
    private struct AssociativityCacheKey: Equatable, Hashable {
        private let first: ObjectIdentifier
        private let second: ObjectIdentifier

        init(_ first: PrecedenceGroup, _ second: PrecedenceGroup) {
            self.first = ObjectIdentifier(first)
            self.second = ObjectIdentifier(second)
        }
    }

    /// A dictionary of known precedence groups, keyed by their names.
    private var precedenceGroups = [PrecedenceGroup.Name: PrecedenceGroup]()

    /// A dictionary of known infix operators, keyed by their name.
    private var infixOperators = [String: InfixOperator]()

    /// A cache of associativities between pairs of operators, computed and cached
    /// on demand.
    private var associativityCache = [AssociativityCacheKey: Associativity?]()

    /// Creates and returns a new operator context that has been populated with
    /// the precedence groups and operators that are built into the Swift compiler
    /// and standard library.
    internal static func makeBuiltinOperatorContext() -> OperatorContext {
        let context = OperatorContext()
        context.addBuiltinOperators()
        return context
    }

    /// Creates a new operator context.
    ///
    /// The new operator context will be completely empty, containing no
    /// precedence groups or operators. These can be added by calling
    /// `addPrecedenceGroup(_:named:)` and `addInfixOperator(_:named:)`.
    ///
    /// The built-in Swift precedence groups and operators can also be added by
    /// calling `addBuiltinOperators`. If this is all you need, you can call the
    /// factory method `makeBuiltinOperatorContext()` as a convenience.
    internal init() {}

    /// Adds the precedence groups and operators that are built into the Swift
    /// compiler and standard library to the operator context.
    internal func addBuiltinOperators() {
        let assignmentPrecedence = PrecedenceGroup(
            associativity: .right, isAssignment: true)
        let functionArrowPrecedence = PrecedenceGroup(
            higherGroups: [assignmentPrecedence], associativity: .right)
        let ternaryPrecedence = PrecedenceGroup(
            higherGroups: [functionArrowPrecedence], associativity: .right)
        let defaultPrecedence = PrecedenceGroup(higherGroups: [ternaryPrecedence])
        let logicalDisjunctionPrecedence = PrecedenceGroup(
            higherGroups: [ternaryPrecedence], associativity: .left)
        let logicalConjunctionPrecedence = PrecedenceGroup(
            higherGroups: [logicalDisjunctionPrecedence], associativity: .left)
        let comparisonPrecedence = PrecedenceGroup(
            higherGroups: [logicalConjunctionPrecedence], associativity: .left)
        let nilCoalescingPrecedence = PrecedenceGroup(
            higherGroups: [comparisonPrecedence], associativity: .right)
        let castingPrecedence = PrecedenceGroup(
            higherGroups: [nilCoalescingPrecedence])
        let rangeFormationPrecedence = PrecedenceGroup(
            higherGroups: [castingPrecedence])
        let additionPrecedence = PrecedenceGroup(
            higherGroups: [rangeFormationPrecedence], associativity: .left)
        let multiplicationPrecedence = PrecedenceGroup(
            higherGroups: [additionPrecedence], associativity: .left)
        let bitwiseShiftPrecedence = PrecedenceGroup(
            higherGroups: [multiplicationPrecedence])

        addPrecedenceGroup(assignmentPrecedence, named: .assignment)
        addPrecedenceGroup(functionArrowPrecedence, named: .functionArrow)
        addPrecedenceGroup(ternaryPrecedence, named: .ternary)
        addPrecedenceGroup(defaultPrecedence, named: .default)
        addPrecedenceGroup(logicalDisjunctionPrecedence, named: .logicalDisjunction)
        addPrecedenceGroup(logicalConjunctionPrecedence, named: .logicalConjunction)
        addPrecedenceGroup(comparisonPrecedence, named: .comparison)
        addPrecedenceGroup(nilCoalescingPrecedence, named: .nilCoalescing)
        addPrecedenceGroup(castingPrecedence, named: .casting)
        addPrecedenceGroup(rangeFormationPrecedence, named: .rangeFormation)
        addPrecedenceGroup(additionPrecedence, named: .addition)
        addPrecedenceGroup(multiplicationPrecedence, named: .multiplication)
        addPrecedenceGroup(bitwiseShiftPrecedence, named: .bitwiseShift)

        // Add the built-in infix operators.
        //
        // Note that the cast operators `as` and `is` and the ternary operator are
        // not registered because `SyntaxExprCanonicalizer` handles `AsExpr`,
        // `IsExpr`, and `TernaryExpr` nodes directly, rather than passing through
        // here.

        addInfixOperator("<<", precedenceGroup: bitwiseShiftPrecedence)
        addInfixOperator("&<<", precedenceGroup: bitwiseShiftPrecedence)
        addInfixOperator(">>", precedenceGroup: bitwiseShiftPrecedence)
        addInfixOperator("&>>", precedenceGroup: bitwiseShiftPrecedence)

        addInfixOperator("*", precedenceGroup: multiplicationPrecedence)
        addInfixOperator("&*", precedenceGroup: multiplicationPrecedence)
        addInfixOperator("/", precedenceGroup: multiplicationPrecedence)
        addInfixOperator("%", precedenceGroup: multiplicationPrecedence)
        addInfixOperator("&", precedenceGroup: multiplicationPrecedence)

        addInfixOperator("+", precedenceGroup: additionPrecedence)
        addInfixOperator("&+", precedenceGroup: additionPrecedence)
        addInfixOperator("-", precedenceGroup: additionPrecedence)
        addInfixOperator("&-", precedenceGroup: additionPrecedence)
        addInfixOperator("|", precedenceGroup: additionPrecedence)
        addInfixOperator("^", precedenceGroup: additionPrecedence)

        addInfixOperator("...", precedenceGroup: rangeFormationPrecedence)
        addInfixOperator("..<", precedenceGroup: rangeFormationPrecedence)

        addInfixOperator("??", precedenceGroup: nilCoalescingPrecedence)

        addInfixOperator("<", precedenceGroup: comparisonPrecedence)
        addInfixOperator("<=", precedenceGroup: comparisonPrecedence)
        addInfixOperator(">", precedenceGroup: comparisonPrecedence)
        addInfixOperator(">=", precedenceGroup: comparisonPrecedence)
        addInfixOperator("==", precedenceGroup: comparisonPrecedence)
        addInfixOperator("!=", precedenceGroup: comparisonPrecedence)
        addInfixOperator("===", precedenceGroup: comparisonPrecedence)
        addInfixOperator("!==", precedenceGroup: comparisonPrecedence)
        addInfixOperator("~=", precedenceGroup: comparisonPrecedence)

        addInfixOperator("&&", precedenceGroup: logicalConjunctionPrecedence)

        addInfixOperator("||", precedenceGroup: logicalDisjunctionPrecedence)

        addInfixOperator("=", precedenceGroup: assignmentPrecedence)
        addInfixOperator("*=", precedenceGroup: assignmentPrecedence)
        addInfixOperator("&*=", precedenceGroup: assignmentPrecedence)
        addInfixOperator("/=", precedenceGroup: assignmentPrecedence)
        addInfixOperator("%=", precedenceGroup: assignmentPrecedence)
        addInfixOperator("+=", precedenceGroup: assignmentPrecedence)
        addInfixOperator("&+=", precedenceGroup: assignmentPrecedence)
        addInfixOperator("-=", precedenceGroup: assignmentPrecedence)
        addInfixOperator("&-=", precedenceGroup: assignmentPrecedence)
        addInfixOperator("<<=", precedenceGroup: assignmentPrecedence)
        addInfixOperator("&<<=", precedenceGroup: assignmentPrecedence)
        addInfixOperator(">>=", precedenceGroup: assignmentPrecedence)
        addInfixOperator("&>>=", precedenceGroup: assignmentPrecedence)
        addInfixOperator("&=", precedenceGroup: assignmentPrecedence)
        addInfixOperator("^=", precedenceGroup: assignmentPrecedence)
        addInfixOperator("|=", precedenceGroup: assignmentPrecedence)

        // SIMD pointwise operators introduced in Swift 5; see
        // <https://github.com/apple/swift-evolution/blob/master/proposals/0229-simd.md>.

        addInfixOperator(".==", precedenceGroup: comparisonPrecedence)
        addInfixOperator(".!=", precedenceGroup: comparisonPrecedence)
        addInfixOperator(".<", precedenceGroup: comparisonPrecedence)
        addInfixOperator(".<=", precedenceGroup: comparisonPrecedence)
        addInfixOperator(".>", precedenceGroup: comparisonPrecedence)
        addInfixOperator(".>=", precedenceGroup: comparisonPrecedence)

        addInfixOperator(".&", precedenceGroup: logicalConjunctionPrecedence)
        addInfixOperator(".^", precedenceGroup: logicalDisjunctionPrecedence)
        addInfixOperator(".|", precedenceGroup: logicalDisjunctionPrecedence)

        addInfixOperator(".&=", precedenceGroup: assignmentPrecedence)
        addInfixOperator(".^=", precedenceGroup: assignmentPrecedence)
        addInfixOperator(".|=", precedenceGroup: assignmentPrecedence)
    }

    /// Returns the precedence group with the given name, or nil if none exists.
    internal func precedenceGroup(named name: PrecedenceGroup.Name)
    -> PrecedenceGroup?
    {
        return precedenceGroups[name]
    }

    /// Adds a precedence group to the context with the given name.
    internal func addPrecedenceGroup(
        _ precedenceGroup: PrecedenceGroup,
        named name: PrecedenceGroup.Name
    ) {
        precedenceGroups[name] = precedenceGroup
    }

    /// Returns the infix operator with the given name, or nil if none exists.
    internal func infixOperator(named name: String) -> InfixOperator? {
        return infixOperators[name]
    }

    /// Adds an infix operator to the context with the given precedence group.
    internal func addInfixOperator(
        _ name: String,
        precedenceGroup: PrecedenceGroup
    ) {
        infixOperators[name] =
        InfixOperator(name: name, precedenceGroup: precedenceGroup)
    }

    /// Returns the associativity between operators in the given precedence
    /// groups.
    internal func associativityBetween(
        _ left: PrecedenceGroup,
        _ right: PrecedenceGroup
    ) -> Associativity? {
        // If the operators are in the same precedence group, use the group's
        // associativity.
        if left === right { return left.associativity }

        // This relationship is antisymmetric, so we can canonicalize to avoid
        // computing it twice. Since precedence groups have identity, if the object
        // identifier of `left` is ordered after the object identifier of `right`,
        // we flip them and then invert the result.
        if ObjectIdentifier(left) < ObjectIdentifier(right) {
            return associativityBetweenImpl(left, right)
        }

        switch associativityBetweenImpl(right, left) {
        case .left: return .right
        case .right: return .left
        case .none: return .none
        }
    }

    /// Returns the associativity between operators in the given precedence
    /// groups, assuming that they are normalized such that the object identifier
    /// of `left` is ordered before the object identifier of `right` to avoid
    /// unnecessary computations.
    private func associativityBetweenImpl(
        _ left: PrecedenceGroup,
        _ right: PrecedenceGroup
    ) -> Associativity? {
        let cacheKey = AssociativityCacheKey(left, right)
        if let associativity = associativityCache[cacheKey] {
            return associativity
        }

        let associativity: Associativity?
        if isHigherPrecedence(left, right) {
            associativity = .left
        } else if isHigherPrecedence(right, left) {
            associativity = .right
        } else {
            associativity = .none
        }
        associativityCache[cacheKey] = associativity
        return associativity
    }

    /// Returns true if operators in the first precedence group have higher
    /// precedence than operators in the second precedence group.
    private func isHigherPrecedence(
        _ first: PrecedenceGroup,
        _ second: PrecedenceGroup
    ) -> Bool {
        precondition(
            first !== second, "exact match should already have been filtered")

        var stack = [PrecedenceGroup]()

        // Compute the transitive set of precedence groups that are explicitly lower
        // than `first` and `second`, including `second` itself. This is expected to
        // be very small, since it's only legal in downstream modules.
        var targets = Set<ObjectIdentifier>()
        targets.insert(ObjectIdentifier(second))
        stack.append(second)
        repeat {
            let current = stack.popLast()!
            for group in current.lowerGroups {
                // If we ever see `first`, we're done.
                if group === first { return true }

                // If we've already inserted this, don't add it to the stack.
                if !targets.insert(ObjectIdentifier(group)).inserted { continue }

                stack.append(group)
            }
        } while !stack.isEmpty

        // Walk down the higherThan relationships from `first` and look for anything
        // in the set we just built.
        stack.append(first)
        repeat {
            let current = stack.popLast()!
            for group in current.higherGroups {
                // If we ever see a group that's in the target set, we're done.
                if targets.contains(ObjectIdentifier(group)) { return true }

                stack.append(group)
            }
        } while !stack.isEmpty

        return false
    }
}

/// A description of an infix operator.
internal struct InfixOperator {

    /// The symbolic name of the operator.
    internal let name: String

    /// The precedence group to which the operator belongs.
    internal let precedenceGroup: PrecedenceGroup

    /// Creates a new infix operator with the given name and precedence group.
    internal init(name: String, precedenceGroup: PrecedenceGroup) {
        self.name = name
        self.precedenceGroup = precedenceGroup
    }
}

/// Describes how neighboring operators in the same precedence group associate
/// with each other.
internal enum Associativity {
    case left
    case right
}

/// A description of a precedence group for operator declarations.
internal final class PrecedenceGroup {

    /// The name of a precedence group.
    internal struct Name: Equatable, Hashable, RawRepresentable {
        internal static let assignment = Name("AssignmentPrecedence")
        internal static let functionArrow = Name("FunctionArrowPrecedence")
        internal static let ternary = Name("TernaryPrecedence")
        internal static let `default` = Name("DefaultPrecedence")
        internal static let logicalDisjunction = Name("LogicalDisjunctionPrecedence")
        internal static let logicalConjunction = Name("LogicalConjunctionPrecedence")
        internal static let comparison = Name("ComparisonPrecedence")
        internal static let nilCoalescing = Name("NilCoalescingPrecedence")
        internal static let casting = Name("CastingPrecedence")
        internal static let rangeFormation = Name("RangeFormationPrecedence")
        internal static let addition = Name("AdditionPrecedence")
        internal static let multiplication = Name("MultiplicationPrecedence")
        internal static let bitwiseShift = Name("BitwiseShiftPrecedence")

        internal let rawValue: String

        internal init(rawValue: String) {
            self.rawValue = rawValue
        }

        internal init(_ rawValue: String) {
            self.init(rawValue: rawValue)
        }
    }

    /// The precedence groups that this one has lower precedence than.
    internal let lowerGroups: [PrecedenceGroup]

    /// The precedence groups that this one has higher precedence than.
    internal let higherGroups: [PrecedenceGroup]

    /// The associativity of the operators in this precedence group, if they are
    /// associative with each other.
    internal let associativity: Associativity?

    /// Indicates whether or not the operator has assignment characteristics.
    internal let isAssignment: Bool

    /// Creates a new precedence group with the given characteristics.
    internal init(
        lowerGroups: [PrecedenceGroup] = [],
        higherGroups: [PrecedenceGroup] = [],
        associativity: Associativity? = nil,
        isAssignment: Bool = false
    ) {
        self.lowerGroups = lowerGroups
        self.higherGroups = higherGroups
        self.associativity = associativity
        self.isAssignment = isAssignment
    }
}
