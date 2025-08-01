import Foundation
import SourceKittenFramework

/// An executable value that can identify issues (violations) in Swift source code.
public protocol Rule: Sendable {
    /// The type of the configuration used to configure this rule.
    associatedtype ConfigurationType: RuleConfiguration

    /// A verbose description of many of this rule's properties.
    static var description: RuleDescription { get }

    /// This rule's configuration.
    var configuration: ConfigurationType { get set }

    /// Whether this rule should be used on empty files. Defaults to `false`.
    var shouldLintEmptyFiles: Bool { get }

    /// A default initializer for rules. All rules need to be trivially initializable.
    init()

    /// Creates a rule by applying its configuration.
    ///
    /// - parameter configuration: The untyped configuration value to apply.
    ///
    /// - throws: Throws if the configuration didn't match the expected format.
    init(configuration: Any) throws

    /// Create a description of how this rule has been configured to run.
    ///
    /// - parameter exclusiveOptions: A set of options that should be excluded from the description.
    ///
    /// - returns: A description of the rule's configuration.
    func createConfigurationDescription(exclusiveOptions: Set<String>) -> RuleConfigurationDescription

    /// Executes the rule on a file and returns any violations to the rule's expectations.
    ///
    /// - parameter file:              The file for which to execute the rule.
    /// - parameter compilerArguments: The compiler arguments needed to compile this file.
    ///
    /// - returns: All style violations to the rule's expectations.
    func validate(file: SwiftLintFile, compilerArguments: [String]) -> [StyleViolation]

    /// Executes the rule on a file and returns any violations to the rule's expectations.
    ///
    /// - parameter file: The file for which to execute the rule.
    ///
    /// - returns: All style violations to the rule's expectations.
    func validate(file: SwiftLintFile) -> [StyleViolation]

    /// Whether or not the specified rule is equivalent to the current rule.
    ///
    /// - parameter rule: The `rule` value to compare against.
    ///
    /// - returns: Whether or not the specified rule is equivalent to the current rule.
    func isEqualTo(_ rule: some Rule) -> Bool

    /// Collects information for the specified file in a storage object, to be analyzed by a `CollectedLinter`.
    ///
    /// - note: This function is called by the linter and is always implemented in extensions.
    ///
    /// - parameter file:              The file for which to collect info.
    /// - parameter storage:           The storage object where collected info should be saved.
    /// - parameter compilerArguments: The compiler arguments needed to compile this file.
    func collectInfo(for file: SwiftLintFile, into storage: RuleStorage, compilerArguments: [String])

    /// Executes the rule on a file after collecting file info for all files and returns any violations to the rule's
    /// expectations.
    ///
    /// - note: This function is called by the linter and is always implemented in extensions.
    ///
    /// - parameter file:              The file for which to execute the rule.
    /// - parameter storage:           The storage object containing all collected info.
    /// - parameter compilerArguments: The compiler arguments needed to compile this file.
    ///
    /// - returns: All style violations to the rule's expectations.
    func validate(file: SwiftLintFile, using storage: RuleStorage, compilerArguments: [String]) -> [StyleViolation]

    /// Checks if a style violation can be disabled by a command specifying a rule ID. Only the rule can claim that for
    /// sure since it knows all the possible identifiers.
    ///
    /// - Parameters:
    ///   - violation: A style violation.
    ///   - ruleID: The name of a rule as used in a disable command.
    ///
    /// - Returns: A boolean value indicating whether the violation can be disabled by the given ID.
    func canBeDisabled(violation: StyleViolation, by ruleID: RuleIdentifier) -> Bool

    /// Checks if a the rule is enabled in a given region. A specific rule ID can be provided in case a rule supports
    /// more than one identifier.
    ///
    /// - Parameters:
    ///   - region: The region to check.
    ///   - ruleID: Rule identifier deviating from the default rule's name.
    ///
    /// - Returns: A boolean value indicating whether the rule is enabled in the given region.
    func isEnabled(in region: Region, for ruleID: String) -> Bool
}

public extension Rule {
    var shouldLintEmptyFiles: Bool {
        false
    }

    init(configuration: Any) throws {
        self.init()
        try self.configuration.apply(configuration: configuration)
    }

    func validate(file: SwiftLintFile, using _: RuleStorage, compilerArguments: [String]) -> [StyleViolation] {
        validate(file: file, compilerArguments: compilerArguments)
    }

    func validate(file: SwiftLintFile, compilerArguments _: [String]) -> [StyleViolation] {
        validate(file: file)
    }

    func isEqualTo(_ rule: some Rule) -> Bool {
        if let rule = rule as? Self {
            return configuration == rule.configuration
        }
        return false
    }

    func collectInfo(for _: SwiftLintFile, into _: RuleStorage, compilerArguments _: [String]) {
        // no-op: only CollectingRules mutate their storage
    }

    /// The cache description which will be used to determine if a previous
    /// cached value is still valid given the new cache value.
    var cacheDescription: String {
        (self as? any CacheDescriptionProvider)?.cacheDescription ?? createConfigurationDescription().oneLiner()
    }

    func createConfigurationDescription(exclusiveOptions: Set<String> = []) -> RuleConfigurationDescription {
        RuleConfigurationDescription.from(configuration: configuration, exclusiveOptions: exclusiveOptions)
    }

    func canBeDisabled(violation: StyleViolation, by ruleID: RuleIdentifier) -> Bool {
        switch ruleID {
        case .all:
            true
        case let .single(identifier: id):
               Self.description.allIdentifiers.contains(id)
            && Self.description.allIdentifiers.contains(violation.ruleIdentifier)
        }
    }

    func isEnabled(in region: Region, for ruleID: String) -> Bool {
        !Self.description.allIdentifiers.contains(ruleID) || region.isRuleEnabled(self)
    }
}

public extension Rule {
    /// The rule's unique identifier which is the same as `Rule.description.identifier`.
    static var identifier: String { description.identifier }
}

/// A rule that is not enabled by default. Rules conforming to this need to be explicitly enabled by users.
public protocol OptInRule: Rule {}

/// A rule that can correct violations.
public protocol CorrectableRule: Rule {
    /// Attempts to correct the violations to this rule in the specified file.
    ///
    /// - parameter file:              The file for which to correct violations.
    /// - parameter compilerArguments: The compiler arguments needed to compile this file.
    ///
    /// - returns: Number of corrections that were applied.
    func correct(file: SwiftLintFile, compilerArguments: [String]) -> Int

    /// Attempts to correct the violations to this rule in the specified file.
    ///
    /// - parameter file: The file for which to correct violations.
    ///
    /// - returns: Number of corrections that were applied.
    func correct(file: SwiftLintFile) -> Int

    /// Attempts to correct the violations to this rule in the specified file after collecting file info for all files
    /// and returns all corrections that were applied.
    ///
    /// - note: This function is called by the linter and is always implemented in extensions.
    ///
    /// - parameter file:              The file for which to execute the rule.
    /// - parameter storage:           The storage object containing all collected info.
    /// - parameter compilerArguments: The compiler arguments needed to compile this file.
    ///
    /// - returns: All corrections that were applied.
    func correct(file: SwiftLintFile, using storage: RuleStorage, compilerArguments: [String]) -> Int
}

public extension CorrectableRule {
    func correct(file: SwiftLintFile, compilerArguments _: [String]) -> Int {
        correct(file: file)
    }
    func correct(file: SwiftLintFile, using _: RuleStorage, compilerArguments: [String]) -> Int {
        correct(file: file, compilerArguments: compilerArguments)
    }
}

/// A correctable rule that can apply its corrections by replacing the content of ranges in the offending file with
/// updated content.
public protocol SubstitutionCorrectableRule: CorrectableRule {
    /// Returns the NSString-based `NSRange`s to be replaced in the specified file.
    ///
    /// - parameter file: The file in which to find ranges of violations for this rule.
    ///
    /// - returns: The NSString-based `NSRange`s to be replaced in the specified file.
    func violationRanges(in file: SwiftLintFile) -> [NSRange]

    /// Returns the substitution to apply for the given range.
    ///
    /// - parameter violationRange: The NSString-based `NSRange` of the violation that should be replaced.
    /// - parameter file:           The file in which the violation should be replaced.
    ///
    /// - returns: The range of the correction and its contents, if one could be computed.
    func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String)?
}

public extension SubstitutionCorrectableRule {
    func correct(file: SwiftLintFile) -> Int {
        let violatingRanges = file.ruleEnabled(violatingRanges: violationRanges(in: file), for: self)
        guard violatingRanges.isNotEmpty else {
            return 0
        }
        var numberOfCorrections = 0
        var contents = file.contents
        for range in violatingRanges.sorted(by: { $0.location > $1.location }) {
            let contentsNSString = contents.bridge()
            if let (rangeToRemove, substitution) = self.substitution(for: range, in: file) {
                contents = contentsNSString.replacingCharacters(in: rangeToRemove, with: substitution)
                numberOfCorrections += 1
            }
        }

        file.write(contents)
        return numberOfCorrections
    }
}

/// A rule that does not need SourceKit to operate and can still operate even after SourceKit has crashed.
public protocol SourceKitFreeRule: Rule {}

/// A rule that may or may not require SourceKit depending on its configuration.
public protocol ConditionallySourceKitFree: Rule {
    /// Whether this rule is currently configured in a way that doesn't require SourceKit.
    var isEffectivelySourceKitFree: Bool { get }
}

public extension Rule {
    /// Whether this rule requires SourceKit to operate.
    /// Returns false if the rule conforms to SourceKitFreeRule or if it conforms to
    /// ConditionallySourceKitFree and is currently configured to not require SourceKit.
    var requiresSourceKit: Bool {
        // Check if rule conforms to SourceKitFreeRule
        if self is any SourceKitFreeRule {
            return false
        }

        // Check if rule is conditionally SourceKit-free and currently doesn't need SourceKit
        if let conditionalRule = self as? any ConditionallySourceKitFree {
            return !conditionalRule.isEffectivelySourceKitFree
        }

        // All other rules require SourceKit
        return true
    }
}

/// A rule that can operate on the post-typechecked AST using compiler arguments. Performs rules that are more like
/// static analysis than syntactic checks.
public protocol AnalyzerRule: OptInRule {}

public extension AnalyzerRule {
    func validate(file _: SwiftLintFile) -> [StyleViolation] {
        queuedFatalError("Must call `validate(file:compilerArguments:)` for AnalyzerRule")
    }
}

/// :nodoc:
public extension AnalyzerRule where Self: CorrectableRule {
    func correct(file _: SwiftLintFile) -> Int {
        queuedFatalError("Must call `correct(file:compilerArguments:)` for AnalyzerRule")
    }
}
