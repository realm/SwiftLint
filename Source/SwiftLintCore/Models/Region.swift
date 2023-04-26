import SwiftSyntax

/// A contiguous region of Swift source code.
public struct Region: Equatable {
    /// The location describing the start of the region. All locations that are less than this value
    /// (earlier in the source file) are not contained in this region.
    public let start: Location
    /// The location describing the end of the region. All locations that are greater than this value
    /// (later in the source file) are not contained in this region.
    public let end: Location
    /// All SwiftLint rule identifiers that are disabled in this region.
    public let disabledRuleIdentifiers: Set<RuleIdentifier>

    /// Creates a Region by setting explicit values for all its properties.
    ///
    /// - parameter start:                   The region's starting location.
    /// - parameter end:                     The region's ending location.
    /// - parameter disabledRuleIdentifiers: All SwiftLint rule identifiers that are disabled in this region.
    public init(start: Location, end: Location, disabledRuleIdentifiers: Set<RuleIdentifier>) {
        self.start = start
        self.end = end
        self.disabledRuleIdentifiers = disabledRuleIdentifiers
    }

    /// Whether the specific location is contained in this region.
    ///
    /// - parameter location: The location to check for containment.
    ///
    /// - returns: True if the specific location is contained in this region.
    public func contains(_ location: Location) -> Bool {
        return start <= location && end >= location
    }

    /// Whether the specified rule is enabled in this region.
    ///
    /// - parameter rule: The rule whose status should be determined.
    ///
    /// - returns: True if the specified rule is enabled in this region.
    public func isRuleEnabled(_ rule: Rule) -> Bool {
        return !isRuleDisabled(rule)
    }

    /// Whether the specified rule is disabled in this region.
    ///
    /// - parameter rule: The rule whose status should be determined.
    ///
    /// - returns: True if the specified rule is disabled in this region.
    public func isRuleDisabled(_ rule: Rule) -> Bool {
        guard !disabledRuleIdentifiers.contains(.all) else {
            return true
        }

        let identifiersToCheck = type(of: rule).description.allIdentifiers
        let regionIdentifiers = Set(disabledRuleIdentifiers.map { $0.stringRepresentation })
        return !regionIdentifiers.isDisjoint(with: identifiersToCheck)
    }

    /// Returns the deprecated rule aliases that are disabling the specified rule in this region.
    /// Returns the empty set if the rule isn't disabled in this region.
    ///
    /// - parameter rule: The rule to check.
    ///
    /// - returns: Deprecated rule aliases.
    public func deprecatedAliasesDisabling(rule: Rule) -> Set<String> {
        let identifiers = type(of: rule).description.deprecatedAliases
        return Set(disabledRuleIdentifiers.map { $0.stringRepresentation }).intersection(identifiers)
    }

    /// Converts this `Region` to a SwiftSyntax `SourceRange`.
    ///
    /// - parameter locationConverter: The SwiftSyntax location converter to use.
    ///
    /// - returns: The `SourceRange` if one was produced.
    func toSourceRange(locationConverter: SourceLocationConverter) -> SourceRange? {
        guard let startLine = start.line, let endLine = end.line else {
            return nil
        }

        let startPosition = locationConverter.position(ofLine: startLine, column: min(1000, start.character ?? 1))
        let endPosition = locationConverter.position(ofLine: endLine, column: min(1000, end.character ?? 1))
        let startLocation = locationConverter.location(for: startPosition)
        let endLocation = locationConverter.location(for: endPosition)
        return SourceRange(start: startLocation, end: endLocation)
    }
}
