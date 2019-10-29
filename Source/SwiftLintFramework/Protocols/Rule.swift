import Foundation
import SourceKittenFramework

public protocol Rule {
    static var description: RuleDescription { get }
    var configurationDescription: String { get }

    init() // Rules need to be able to be initialized with default values
    init(configuration: Any) throws

    func validate(file: SwiftLintFile, compilerArguments: [String]) -> [StyleViolation]
    func validate(file: SwiftLintFile) -> [StyleViolation]
    func isEqualTo(_ rule: Rule) -> Bool

    // These are called by the linter and are always implemented in extensions.
    func collectInfo(for file: SwiftLintFile, into storage: RuleStorage, compilerArguments: [String])
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
        return type(of: self).description == type(of: rule).description
    }

    public func collectInfo(for file: SwiftLintFile, into storage: RuleStorage, compilerArguments: [String]) {
        // no-op: only CollectingRules mutate their storage
    }

    internal var cacheDescription: String {
        return (self as? CacheDescriptionProvider)?.cacheDescription ?? configurationDescription
    }
}

public protocol OptInRule: Rule {}

public protocol AutomaticTestableRule: Rule {}

public protocol ConfigurationProviderRule: Rule {
    associatedtype ConfigurationType: RuleConfiguration

    var configuration: ConfigurationType { get set }
}

public protocol CorrectableRule: Rule {
    func correct(file: SwiftLintFile, compilerArguments: [String]) -> [Correction]
    func correct(file: SwiftLintFile) -> [Correction]

    // Called by the linter and are always implemented in extensions.
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

public protocol SubstitutionCorrectableRule: CorrectableRule {
    func violationRanges(in file: SwiftLintFile) -> [NSRange]
    func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String)
}

public extension SubstitutionCorrectableRule {
    func correct(file: SwiftLintFile) -> [Correction] {
        let violatingRanges = file.ruleEnabled(violatingRanges: violationRanges(in: file), for: self)
        guard !violatingRanges.isEmpty else { return [] }

        let description = type(of: self).description
        var corrections = [Correction]()
        var contents = file.contents
        for range in violatingRanges.sorted(by: { $0.location > $1.location }) {
            let contentsNSString = contents.bridge()

            let (rangeToRemove, substitution) = self.substitution(for: range, in: file)
            contents = contentsNSString.replacingCharacters(in: rangeToRemove, with: substitution)
            let location = Location(file: file, characterOffset: range.location)
            corrections.append(Correction(ruleDescription: description, location: location))
        }

        file.write(contents)
        return corrections
    }
}

public protocol SubstitutionCorrectableASTRule: SubstitutionCorrectableRule, ASTRule {
    func violationRanges(in file: SwiftLintFile, kind: KindType,
                         dictionary: SourceKittenDictionary) -> [NSRange]
}

extension SubstitutionCorrectableASTRule where KindType.RawValue == String {
    public func violationRanges(in file: SwiftLintFile) -> [NSRange] {
        return violationRanges(in: file, dictionary: file.structureDictionary)
    }

    private func violationRanges(in file: SwiftLintFile,
                                 dictionary: SourceKittenDictionary) -> [NSRange] {
        let ranges = dictionary.substructure.flatMap { subDict -> [NSRange] in
            var ranges = violationRanges(in: file, dictionary: subDict)

            if let kind = self.kind(from: subDict) {
                ranges += violationRanges(in: file, kind: kind, dictionary: subDict)
            }

            return ranges
        }

        return ranges.unique
    }
}

public protocol SourceKitFreeRule: Rule {}

public protocol AnalyzerRule: OptInRule {}

public extension AnalyzerRule {
    func validate(file: SwiftLintFile) -> [StyleViolation] {
        queuedFatalError("Must call `validate(file:compilerArguments:)` for AnalyzerRule")
    }
}

public extension AnalyzerRule where Self: CorrectableRule {
    func correct(file: SwiftLintFile) -> [Correction] {
        queuedFatalError("Must call `correct(file:compilerArguments:)` for AnalyzerRule")
    }
}

// MARK: - Collecting rules

/// Type-erased protocol used to check whether a rule is collectable.
public protocol AnyCollectingRule: Rule { }

public protocol CollectingRule: AnyCollectingRule {
    associatedtype FileInfo
    func collectInfo(for file: SwiftLintFile, compilerArguments: [String]) -> FileInfo
    func collectInfo(for file: SwiftLintFile) -> FileInfo
    func validate(file: SwiftLintFile, collectedInfo: [SwiftLintFile: FileInfo],
                  compilerArguments: [String]) -> [StyleViolation]
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

public protocol CollectingCorrectableRule: CollectingRule, CorrectableRule {
    func correct(file: SwiftLintFile, collectedInfo: [SwiftLintFile: FileInfo],
                 compilerArguments: [String]) -> [Correction]
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

public extension Array where Element == Rule {
    static func == (lhs: Array, rhs: Array) -> Bool {
        if lhs.count != rhs.count { return false }
        return !zip(lhs, rhs).contains { !$0.0.isEqualTo($0.1) }
    }
}
