import SwiftSyntax

/// A SwiftLint Rule backed by SwiftSyntax that does not use SourceKit requests.
public protocol SwiftSyntaxRule: SourceKitFreeRule {
    /// Produce a `ViolationsSyntaxVisitor` for the given file.
    ///
    /// - parameter file: The file for which to produce the visitor.
    ///
    /// - returns: A `ViolationsSyntaxVisitor` for the given file.
    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor?

    /// Produce a violation for the given file and absolute position.
    ///
    /// - parameter file:     The file for which to produce the violation.
    /// - parameter position: The absolute position in the file where the violation should be located.
    ///
    /// - returns: A violation for the given file and absolute position.
    func makeViolation(file: SwiftLintFile, position: AbsolutePosition) -> StyleViolation
}

public extension SwiftSyntaxRule where Self: ConfigurationProviderRule, ConfigurationType == SeverityConfiguration {
    func makeViolation(file: SwiftLintFile, position: AbsolutePosition) -> StyleViolation {
        StyleViolation(
            ruleDescription: Self.description,
            severity: configuration.severity,
            location: Location(file: file, position: position)
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
        guard let locationConverter = file.locationConverter else {
            return []
        }

        return file.regions()
            .filter { $0.isRuleDisabled(self) }
            .compactMap { $0.toSourceRange(locationConverter: locationConverter) }
    }

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        guard let visitor = makeVisitor(file: file) else {
            return []
        }

        return visitor
            .walk(file: file, handler: \.violationPositions)
            .sorted()
            .map { makeViolation(file: file, position: $0) }
    }
}

/// A SwiftSyntax `SyntaxVisitor` that produces absolute positions where violations should be reported.
public protocol ViolationsSyntaxVisitor: SyntaxVisitor {
    /// Positions in a source file where violations should be reported.
    var violationPositions: [AbsolutePosition] { get }
}
