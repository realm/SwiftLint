import SwiftSyntax

/// A SwiftLint Rule backed by SwiftSyntax that does not use SourceKit requests.
public protocol SwiftSyntaxRule: SourceKitFreeRule {
    /// Produce a `ViolationsSyntaxVisitor` for the given file.
    ///
    /// - parameter file: The file for which to produce the visitor.
    ///
    /// - returns: A `ViolationsSyntaxVisitor` for the given file.
    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor

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

public extension SwiftSyntaxRule where Self: ConfigurationProviderRule,
                                       ConfigurationType: SeverityBasedRuleConfiguration {
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
    /// Returns the source ranges in the specified file where this rule is disabled.
    ///
    /// - parameter file: The file to get regions.
    ///
    /// - returns: The source ranges in the specified file where this rule is disabled.
    func disabledRegions(file: SwiftLintFile) -> [SourceRange] {
        let locationConverter = file.locationConverter
        return file.regions()
            .filter { $0.isRuleDisabled(self) }
            .compactMap { $0.toSourceRange(locationConverter: locationConverter) }
    }

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        guard let syntaxTree = preprocess(file: file) else {
            return []
        }

        return makeVisitor(file: file)
            .walk(tree: syntaxTree, handler: \.violations)
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
    /// The violation's position.
    public let position: AbsolutePosition
    /// A specific reason for the violation.
    public let reason: String?
    /// The violation's severity.
    public let severity: ViolationSeverity?

    /// Creates a `ReasonedRuleViolation`.
    ///
    /// - parameter position: The violations position in the analyzed source file.
    /// - parameter reason: The reason for the violation if different from the rule's description.
    /// - parameter severity: The severity of the violation if different from the rule's default configured severity.
    public init(position: AbsolutePosition, reason: String? = nil, severity: ViolationSeverity? = nil) {
        self.position = position
        self.reason = reason
        self.severity = severity
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.position < rhs.position
    }
}

/// Extension for arrays of `ReasonedRuleViolation`s that provides the automatic conversion of
/// `AbsolutePosition`s into `ReasonedRuleViolation`s (without a specific reason).
public extension Array where Element == ReasonedRuleViolation {
    /// Append a minimal violation for the specified position.
    ///
    /// - parameter position: The position for the violation to append.
    mutating func append(_ position: AbsolutePosition) {
        append(ReasonedRuleViolation(position: position))
    }

    /// Append minimal violations for the specified positions.
    ///
    /// - parameter positions: The positions for the violations to append.
    mutating func append(contentsOf positions: [AbsolutePosition]) {
        append(contentsOf: positions.map { ReasonedRuleViolation(position: $0) })
    }
}
