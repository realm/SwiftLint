import Foundation
import SourceKittenFramework

/// An executable value that can identify issues (violations) in Swift source code.
public protocol Rule {
    /// A verbose description of many of this rule's properties.
    static var description: RuleDescription { get }

    /// A description of how this rule has been configured to run.
    var configurationDescription: String { get }

    /// A default initializer for rules. All rules need to be trivially initializable.
    init()

    /// Creates a rule by applying its configuration.
    ///
    /// - parameter configuration: The untyped configuration value to apply.
    ///
    /// - throws: Throws if the configuration didn't match the expected format.
    init(configuration: Any) throws

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
    func isEqualTo(_ rule: Rule) -> Bool

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
}

extension Rule {
    public func validate(file: SwiftLintFile, using storage: RuleStorage,
                         compilerArguments: [String]) -> [StyleViolation] {
        return validate(file: file, compilerArguments: compilerArguments)
    }

    public func validate(file: SwiftLintFile, compilerArguments: [String]) -> [StyleViolation] {
        return validate(file: file)
    }

    public func isEqualTo(_ rule: Rule) -> Bool {
        return Self.description == type(of: rule).description
    }

    public func collectInfo(for file: SwiftLintFile, into storage: RuleStorage, compilerArguments: [String]) {
        // no-op: only CollectingRules mutate their storage
    }

    internal var cacheDescription: String {
        return (self as? CacheDescriptionProvider)?.cacheDescription ?? configurationDescription
    }
}

/// A rule that is not enabled by default. Rules conforming to this need to be explicitly enabled by users.
public protocol OptInRule: Rule {}

/// A rule that is user-configurable.
public protocol ConfigurationProviderRule: Rule {
    /// The type of configuration used to configure this rule.
    associatedtype ConfigurationType: RuleConfiguration

    /// This rule's configuration.
    var configuration: ConfigurationType { get set }
}

/// A rule that can correct violations.
public protocol CorrectableRule: Rule {
    /// Attempts to correct the violations to this rule in the specified file.
    ///
    /// - parameter file:              The file for which to correct violations.
    /// - parameter compilerArguments: The compiler arguments needed to compile this file.
    ///
    /// - returns: All corrections that were applied.
    func correct(file: SwiftLintFile, compilerArguments: [String]) -> [Correction]

    /// Attempts to correct the violations to this rule in the specified file.
    ///
    /// - parameter file: The file for which to correct violations.
    ///
    /// - returns: All corrections that were applied.
    func correct(file: SwiftLintFile) -> [Correction]

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
    func correct(file: SwiftLintFile, using storage: RuleStorage, compilerArguments: [String]) -> [Correction]
}

public extension CorrectableRule {
    func correct(file: SwiftLintFile, compilerArguments: [String]) -> [Correction] {
        return correct(file: file)
    }
    func correct(file: SwiftLintFile, using storage: RuleStorage, compilerArguments: [String]) -> [Correction] {
        return correct(file: file, compilerArguments: compilerArguments)
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
    func correct(file: SwiftLintFile) -> [Correction] {
        let violatingRanges = file.ruleEnabled(violatingRanges: violationRanges(in: file), for: self)
        guard violatingRanges.isNotEmpty else { return [] }

        let description = Self.description
        var corrections = [Correction]()
        var contents = file.contents
        for range in violatingRanges.sorted(by: { $0.location > $1.location }) {
            let contentsNSString = contents.bridge()
            if let (rangeToRemove, substitution) = self.substitution(for: range, in: file) {
                contents = contentsNSString.replacingCharacters(in: rangeToRemove, with: substitution)
                let location = Location(file: file, characterOffset: range.location)
                corrections.append(Correction(ruleDescription: description, location: location))
            }
        }

        file.write(contents)
        return corrections
    }
}

/// A `SubstitutionCorrectableRule` that is also an `ASTRule`.
public protocol SubstitutionCorrectableASTRule: SubstitutionCorrectableRule, ASTRule {
    /// Returns the NSString-based `NSRange`s to be replaced in the specified file.
    ///
    /// - parameter file:       The file in which to find ranges of violations for this rule.
    /// - parameter kind:       The kind of token being recursed over.
    /// - parameter dictionary: The dictionary for an AST subset to validate.
    ///
    /// - returns: The NSString-based `NSRange`s to be replaced in the specified file.
    func violationRanges(in file: SwiftLintFile, kind: KindType,
                         dictionary: SourceKittenDictionary) -> [NSRange]
}

public extension SubstitutionCorrectableASTRule {
    func violationRanges(in file: SwiftLintFile) -> [NSRange] {
        return file.structureDictionary.traverseDepthFirst { subDict in
            guard let kind = self.kind(from: subDict) else { return nil }
            return violationRanges(in: file, kind: kind, dictionary: subDict)
        }
    }
}

/// A rule that does not need SourceKit to operate and can still operate even after SourceKit has crashed.
public protocol SourceKitFreeRule: Rule {}

/// A rule that can operate on the post-typechecked AST using compiler arguments. Performs rules that are more like
/// static analysis than syntactic checks.
public protocol AnalyzerRule: OptInRule {}

public extension AnalyzerRule {
    func validate(file: SwiftLintFile) -> [StyleViolation] {
        queuedFatalError("Must call `validate(file:compilerArguments:)` for AnalyzerRule")
    }
}

/// :nodoc:
public extension AnalyzerRule where Self: CorrectableRule {
    func correct(file: SwiftLintFile) -> [Correction] {
        queuedFatalError("Must call `correct(file:compilerArguments:)` for AnalyzerRule")
    }
}

// MARK: - Collecting rules

/// Type-erased protocol used to check whether a rule is collectable.
public protocol AnyCollectingRule: Rule { }

/// A rule that requires knowledge of all other files being linted.
public protocol CollectingRule: AnyCollectingRule {
    /// The kind of information to collect for each file being linted for this rule.
    associatedtype FileInfo

    /// Collects information for the specified file, to be analyzed by a `CollectedLinter`.
    ///
    /// - parameter file:              The file for which to collect info.
    /// - parameter compilerArguments: The compiler arguments needed to compile this file.
    ///
    /// - returns: The collected file information.
    func collectInfo(for file: SwiftLintFile, compilerArguments: [String]) -> FileInfo

    /// Collects information for the specified file, to be analyzed by a `CollectedLinter`.
    ///
    /// - parameter file: The file for which to collect info.
    ///
    /// - returns: The collected file information.
    func collectInfo(for file: SwiftLintFile) -> FileInfo

    /// Executes the rule on a file after collecting file info for all files and returns any violations to the rule's
    /// expectations.
    ///
    /// - parameter file:              The file for which to execute the rule.
    /// - parameter collectedInfo:     All collected info for all files.
    /// - parameter compilerArguments: The compiler arguments needed to compile this file.
    ///
    /// - returns: All style violations to the rule's expectations.
    func validate(file: SwiftLintFile, collectedInfo: [SwiftLintFile: FileInfo],
                  compilerArguments: [String]) -> [StyleViolation]

    /// Executes the rule on a file after collecting file info for all files and returns any violations to the rule's
    /// expectations.
    ///
    /// - parameter file:          The file for which to execute the rule.
    /// - parameter collectedInfo: All collected info for all files.
    ///
    /// - returns: All style violations to the rule's expectations.
    func validate(file: SwiftLintFile, collectedInfo: [SwiftLintFile: FileInfo]) -> [StyleViolation]
}

public extension CollectingRule {
    func collectInfo(for file: SwiftLintFile, into storage: RuleStorage, compilerArguments: [String]) {
        storage.collect(info: collectInfo(for: file, compilerArguments: compilerArguments),
                        for: file, in: self)
    }
    func validate(file: SwiftLintFile, using storage: RuleStorage, compilerArguments: [String]) -> [StyleViolation] {
        guard let info = storage.collectedInfo(for: self) else {
            queuedFatalError("Attempt to validate a CollectingRule before collecting info for it")
        }
        return validate(file: file, collectedInfo: info, compilerArguments: compilerArguments)
    }
    func collectInfo(for file: SwiftLintFile, compilerArguments: [String]) -> FileInfo {
        return collectInfo(for: file)
    }
    func validate(file: SwiftLintFile, collectedInfo: [SwiftLintFile: FileInfo],
                  compilerArguments: [String]) -> [StyleViolation] {
        return validate(file: file, collectedInfo: collectedInfo)
    }
    func validate(file: SwiftLintFile) -> [StyleViolation] {
        queuedFatalError("Must call `validate(file:collectedInfo:)` for CollectingRule")
    }
    func validate(file: SwiftLintFile, compilerArguments: [String]) -> [StyleViolation] {
        queuedFatalError("Must call `validate(file:collectedInfo:compilerArguments:)` for CollectingRule")
    }
}

public extension CollectingRule where Self: AnalyzerRule {
    func collectInfo(for file: SwiftLintFile) -> FileInfo {
        queuedFatalError(
            "Must call `collect(infoFor:compilerArguments:)` for AnalyzerRule & CollectingRule"
        )
    }
    func validate(file: SwiftLintFile) -> [StyleViolation] {
        queuedFatalError(
            "Must call `validate(file:collectedInfo:compilerArguments:)` for AnalyzerRule & CollectingRule"
        )
    }
    func validate(file: SwiftLintFile, collectedInfo: [SwiftLintFile: FileInfo]) -> [StyleViolation] {
        queuedFatalError(
            "Must call `validate(file:collectedInfo:compilerArguments:)` for AnalyzerRule & CollectingRule"
        )
    }
}

/// A `CollectingRule` that is also a `CorrectableRule`.
public protocol CollectingCorrectableRule: CollectingRule, CorrectableRule {
    /// Attempts to correct the violations to this rule in the specified file after collecting file info for all files
    /// and returns all corrections that were applied.
    ///
    /// - note: This function is called by the linter and is always implemented in extensions.
    ///
    /// - parameter file:              The file for which to execute the rule.
    /// - parameter collectedInfo:     All collected info.
    /// - parameter compilerArguments: The compiler arguments needed to compile this file.
    ///
    /// - returns: All corrections that were applied.
    func correct(file: SwiftLintFile, collectedInfo: [SwiftLintFile: FileInfo],
                 compilerArguments: [String]) -> [Correction]

    /// Attempts to correct the violations to this rule in the specified file after collecting file info for all files
    /// and returns all corrections that were applied.
    ///
    /// - note: This function is called by the linter and is always implemented in extensions.
    ///
    /// - parameter file:          The file for which to execute the rule.
    /// - parameter collectedInfo: All collected info.
    ///
    /// - returns: All corrections that were applied.
    func correct(file: SwiftLintFile, collectedInfo: [SwiftLintFile: FileInfo]) -> [Correction]
}

public extension CollectingCorrectableRule {
    func correct(file: SwiftLintFile, collectedInfo: [SwiftLintFile: FileInfo],
                 compilerArguments: [String]) -> [Correction] {
        return correct(file: file, collectedInfo: collectedInfo)
    }
    func correct(file: SwiftLintFile, using storage: RuleStorage, compilerArguments: [String]) -> [Correction] {
        guard let info = storage.collectedInfo(for: self) else {
            queuedFatalError("Attempt to correct a CollectingRule before collecting info for it")
        }
        return correct(file: file, collectedInfo: info, compilerArguments: compilerArguments)
    }
    func correct(file: SwiftLintFile) -> [Correction] {
        queuedFatalError("Must call `correct(file:collectedInfo:)` for AnalyzerRule")
    }
    func correct(file: SwiftLintFile, compilerArguments: [String]) -> [Correction] {
        queuedFatalError("Must call `correct(file:collectedInfo:compilerArguments:)` for AnalyzerRule")
    }
}

public extension CollectingCorrectableRule where Self: AnalyzerRule {
    func correct(file: SwiftLintFile) -> [Correction] {
        queuedFatalError("Must call `correct(file:collectedInfo:compilerArguments:)` for AnalyzerRule")
    }
    func correct(file: SwiftLintFile, compilerArguments: [String]) -> [Correction] {
        queuedFatalError("Must call `correct(file:collectedInfo:compilerArguments:)` for AnalyzerRule")
    }
    func correct(file: SwiftLintFile, collectedInfo: [SwiftLintFile: FileInfo]) -> [Correction] {
        queuedFatalError("Must call `correct(file:collectedInfo:compilerArguments:)` for AnalyzerRule")
    }
}

public extension ConfigurationProviderRule {
    init(configuration: Any) throws {
        self.init()
        try self.configuration.apply(configuration: configuration)
    }

    func isEqualTo(_ rule: Rule) -> Bool {
        if let rule = rule as? Self {
            return configuration.isEqualTo(rule.configuration)
        }
        return false
    }

    var configurationDescription: String {
        return configuration.consoleDescription
    }
}

// MARK: - == Implementations

/// :nodoc:
public extension Array where Element == Rule {
    static func == (lhs: Array, rhs: Array) -> Bool {
        if lhs.count != rhs.count { return false }
        return !zip(lhs, rhs).contains { !$0.0.isEqualTo($0.1) }
    }
}
