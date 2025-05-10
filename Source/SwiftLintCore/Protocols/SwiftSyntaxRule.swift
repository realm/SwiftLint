import SwiftSyntax

/// A SwiftLint Rule backed by SwiftSyntax that does not use SourceKit requests.
public protocol SwiftSyntaxRule: SourceKitFreeRule {
    /// Produce a `ViolationsSyntaxVisitor` for the given file.
    ///
    /// - parameter file: The file for which to produce the visitor.
    ///
    /// - returns: A `ViolationsSyntaxVisitor` for the given file.
    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor<ConfigurationType>

    /// Produce a violation for the given file and absolute position.
    ///
    /// - parameter file:      The file for which to produce the violation.
    /// - parameter violation: A violation in the file.
    ///
    /// - returns: A violation for the given file and absolute position.
    func makeViolation(file: SwiftLintFile, violation: ReasonedRuleViolation) -> StyleViolation

    /// Gives a chance for the rule to do some pre-processing on the syntax tree.
    /// One typical example is using `SwiftOperators` to "fold" the tree, resolving operators precedence.
    /// This can also be used to skip validation in a given file.
    /// By default, it just returns the file's `syntaxTree`.
    ///
    /// - parameter file: The file to run pre-processing on.
    ///
    /// - returns: The tree that will be used to check for violations. If `nil`, this rule will return no violations.
    func preprocess(file: SwiftLintFile) -> SourceFileSyntax?
}

public extension SwiftSyntaxRule where ConfigurationType: SeverityBasedRuleConfiguration {
    func makeViolation(file: SwiftLintFile, violation: ReasonedRuleViolation) -> StyleViolation {
        StyleViolation(
            ruleDescription: Self.description,
            severity: violation.severity ?? configuration.severity,
            location: Location(file: file, position: violation.position),
            reason: violation.reason
        )
    }
}

public extension SwiftSyntaxRule {
    @inlinable
    func validate(file: SwiftLintFile) -> [StyleViolation] {
        guard let syntaxTree = preprocess(file: file) else {
            return []
        }

        let violations = makeVisitor(file: file)
            .walk(tree: syntaxTree, handler: \.violations)
        assert(
            violations.allSatisfy { $0.correction == nil || self is any SwiftSyntaxCorrectableRule },
            "\(Self.self) produced corrections without being correctable."
        )
        return violations
            .sorted()
            .map { makeViolation(file: file, violation: $0) }
    }

    func makeViolation(file: SwiftLintFile, violation: ReasonedRuleViolation) -> StyleViolation {
        guard let severity = violation.severity else {
            // This error will only be thrown in tests. It cannot come up at runtime.
            queuedFatalError("""
                A severity must be provided. Either define it in the violation or make the rule configuration \
                conform to `SeverityBasedRuleConfiguration` to take the default.
                """)
        }
        return StyleViolation(
            ruleDescription: Self.description,
            severity: severity,
            location: Location(file: file, position: violation.position),
            reason: violation.reason
        )
    }

    func preprocess(file: SwiftLintFile) -> SourceFileSyntax? {
        file.syntaxTree
    }
}

/// A violation produced by `ViolationsSyntaxVisitor`s.
public struct ReasonedRuleViolation: Comparable, Hashable {
    /// The correction of a violation that is basically the violation's range in the source code and a
    /// replacement for this range that would fix the violation.
    public struct ViolationCorrection: Hashable {
        /// Start position of the violation range.
        let start: AbsolutePosition
        /// End position of the violation range.
        let end: AbsolutePosition
        /// Replacement for the violating range.
        let replacement: String

        /// Create a ``ViolationCorrection``.
        /// - Parameters:
        ///   - start:          Start position of the violation range.
        ///   - end:            End position of the violation range.
        ///   - replacement:    Replacement for the violating range.
        public init(start: AbsolutePosition, end: AbsolutePosition, replacement: String) {
            self.start = start
            self.end = end
            self.replacement = replacement
        }
    }

    /// The violation's position.
    public let position: AbsolutePosition
    /// A specific reason for the violation.
    public let reason: String?
    /// The violation's severity.
    public let severity: ViolationSeverity?
    /// An optional correction of the violation to be used in rewriting (see ``SwiftSyntaxCorrectableRule``). Can be
    /// left unset when creating a violation, especially if the rule is not correctable or provides a custom rewriter.
    public let correction: ViolationCorrection?

    /// Creates a `ReasonedRuleViolation`.
    ///
    /// - Parameters:
    ///   - position: The violations position in the analyzed source file.
    ///   - reason: The reason for the violation if different from the rule's description.
    ///   - severity: The severity of the violation if different from the rule's default configured severity.
    ///   - correction: An optional correction of the violation to be used in rewriting.
    public init(position: AbsolutePosition,
                reason: String? = nil,
                severity: ViolationSeverity? = nil,
                correction: ViolationCorrection? = nil) {
        self.position = position
        self.reason = reason
        self.severity = severity
        self.correction = correction
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.position < rhs.position
    }
}

/// Extension for arrays of `ReasonedRuleViolation`s that provides the automatic conversion of
/// `AbsolutePosition`s into `ReasonedRuleViolation`s (without a specific reason).
public extension Array where Element == ReasonedRuleViolation {
    /// Add a violation at the specified position using the default description and severity.
    ///
    /// - parameter position: The position for the violation to append.
    mutating func append(_ position: AbsolutePosition) {
        append(ReasonedRuleViolation(position: position))
    }

    /// Add a violation and the correction at the specified position using the default description and severity.
    ///
    /// - parameter position: The position for the violation to append.
    /// - parameter correction: An optional correction to be applied when running with `--fix`.
    mutating func append(at position: AbsolutePosition, correction: ReasonedRuleViolation.ViolationCorrection? = nil) {
        append(ReasonedRuleViolation(position: position, correction: correction))
    }

    /// Add violations for the specified positions using the default description and severity.
    ///
    /// - parameter positions: The positions for the violations to append.
    mutating func append(contentsOf positions: [AbsolutePosition]) {
        append(contentsOf: positions.map { ReasonedRuleViolation(position: $0) })
    }
}
