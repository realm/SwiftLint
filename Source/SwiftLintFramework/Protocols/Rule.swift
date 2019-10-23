import Foundation
import SourceKittenFramework

public protocol Rule {
    static var description: RuleDescription { get }
    var configurationDescription: String { get }

    init() // Rules need to be able to be initialized with default values
    init(configuration: Any) throws

    func validate(file: File, compilerArguments: [String]) -> [StyleViolation]
    func validate(file: File) -> [StyleViolation]
    func isEqualTo(_ rule: Rule) -> Bool

    // These are called by the linter and are always implemented in extensions.
    func collectInfo(for file: File, into storage: RuleStorage, compilerArguments: [String])
    func validate(file: File, using storage: RuleStorage, compilerArguments: [String]) -> [StyleViolation]
}

extension Rule {
    public func validate(file: File, using storage: RuleStorage, compilerArguments: [String]) -> [StyleViolation] {
        return validate(file: file, compilerArguments: compilerArguments)
    }

    public func validate(file: File, compilerArguments: [String]) -> [StyleViolation] {
        return validate(file: file)
    }

    public func isEqualTo(_ rule: Rule) -> Bool {
        return type(of: self).description == type(of: rule).description
    }

    public func collectInfo(for file: File, into storage: RuleStorage, compilerArguments: [String]) {
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
    func correct(file: File, compilerArguments: [String]) -> [Correction]
    func correct(file: File) -> [Correction]

    // Called by the linter and are always implemented in extensions.
    func correct(file: File, using storage: RuleStorage, compilerArguments: [String]) -> [Correction]
}

public extension CorrectableRule {
    func correct(file: File, compilerArguments: [String]) -> [Correction] {
        return correct(file: file)
    }
    func correct(file: File, using storage: RuleStorage, compilerArguments: [String]) -> [Correction] {
        return correct(file: file, compilerArguments: compilerArguments)
    }
}

public protocol SubstitutionCorrectableRule: CorrectableRule {
    func violationRanges(in file: File) -> [NSRange]
    func substitution(for violationRange: NSRange, in file: File) -> (NSRange, String)
}

public extension SubstitutionCorrectableRule {
    func correct(file: File) -> [Correction] {
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
    func violationRanges(in file: File, kind: KindType,
                         dictionary: SourceKittenDictionary) -> [NSRange]
}

extension SubstitutionCorrectableASTRule where KindType.RawValue == String {
    public func violationRanges(in file: File) -> [NSRange] {
        return violationRanges(in: file, dictionary: SourceKittenDictionary(value: file.structure.dictionary))
    }

    private func violationRanges(in file: File,
                                 dictionary: SourceKittenDictionary) -> [NSRange] {
        let ranges = dictionary.substructure.flatMap { subDict -> [NSRange] in
            var ranges = violationRanges(in: file, dictionary: subDict)

            if let kind = subDict.kind.flatMap(KindType.init) {
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
    func validate(file: File) -> [StyleViolation] {
        queuedFatalError("Must call `validate(file:compilerArguments:)` for AnalyzerRule")
    }
}

public extension AnalyzerRule where Self: CorrectableRule {
    func correct(file: File) -> [Correction] {
        queuedFatalError("Must call `correct(file:compilerArguments:)` for AnalyzerRule")
    }
}

// MARK: - Collecting rules

/// Type-erased protocol used to check whether a rule is collectable.
public protocol AnyCollectingRule: Rule { }

public protocol CollectingRule: AnyCollectingRule {
    associatedtype FileInfo
    func collectInfo(for file: File, compilerArguments: [String]) -> FileInfo
    func collectInfo(for file: File) -> FileInfo
    func validate(file: File, collectedInfo: [File: FileInfo], compilerArguments: [String]) -> [StyleViolation]
    func validate(file: File, collectedInfo: [File: FileInfo]) -> [StyleViolation]
}

public extension CollectingRule {
    func collectInfo(for file: File, into storage: RuleStorage, compilerArguments: [String]) {
        storage.collect(info: collectInfo(for: file, compilerArguments: compilerArguments),
                        for: file, in: self)
    }
    func validate(file: File, using storage: RuleStorage, compilerArguments: [String]) -> [StyleViolation] {
        guard let info = storage.collectedInfo(for: self) else {
            queuedFatalError("Attempt to validate a CollectingRule before collecting info for it")
        }
        return validate(file: file, collectedInfo: info, compilerArguments: compilerArguments)
    }
    func collectInfo(for file: File, compilerArguments: [String]) -> FileInfo {
        return collectInfo(for: file)
    }
    func validate(file: File, collectedInfo: [File: FileInfo], compilerArguments: [String]) -> [StyleViolation] {
        return validate(file: file, collectedInfo: collectedInfo)
    }
    func validate(file: File) -> [StyleViolation] {
        queuedFatalError("Must call `validate(file:collectedInfo:)` for CollectingRule")
    }
    func validate(file: File, compilerArguments: [String]) -> [StyleViolation] {
        queuedFatalError("Must call `validate(file:collectedInfo:compilerArguments:)` for CollectingRule")
    }
}

public extension CollectingRule where Self: AnalyzerRule {
    func collectInfo(for file: File) -> FileInfo {
        queuedFatalError(
            "Must call `collect(infoFor:compilerArguments:)` for AnalyzerRule & CollectingRule"
        )
    }
    func validate(file: File) -> [StyleViolation] {
        queuedFatalError(
            "Must call `validate(file:collectedInfo:compilerArguments:)` for AnalyzerRule & CollectingRule"
        )
    }
    func validate(file: File, collectedInfo: [File: FileInfo]) -> [StyleViolation] {
        queuedFatalError(
            "Must call `validate(file:collectedInfo:compilerArguments:)` for AnalyzerRule & CollectingRule"
        )
    }
}

public protocol CollectingCorrectableRule: CollectingRule, CorrectableRule {
    func correct(file: File, collectedInfo: [File: FileInfo], compilerArguments: [String]) -> [Correction]
    func correct(file: File, collectedInfo: [File: FileInfo]) -> [Correction]
}

public extension CollectingCorrectableRule {
    func correct(file: File, collectedInfo: [File: FileInfo], compilerArguments: [String]) -> [Correction] {
        return correct(file: file, collectedInfo: collectedInfo)
    }
    func correct(file: File, using storage: RuleStorage, compilerArguments: [String]) -> [Correction] {
        guard let info = storage.collectedInfo(for: self) else {
            queuedFatalError("Attempt to correct a CollectingRule before collecting info for it")
        }
        return correct(file: file, collectedInfo: info, compilerArguments: compilerArguments)
    }
    func correct(file: File) -> [Correction] {
        queuedFatalError("Must call `correct(file:collectedInfo:)` for AnalyzerRule")
    }
    func correct(file: File, compilerArguments: [String]) -> [Correction] {
        queuedFatalError("Must call `correct(file:collectedInfo:compilerArguments:)` for AnalyzerRule")
    }
}

public extension CollectingCorrectableRule where Self: AnalyzerRule {
    func correct(file: File) -> [Correction] {
        queuedFatalError("Must call `correct(file:collectedInfo:compilerArguments:)` for AnalyzerRule")
    }
    func correct(file: File, compilerArguments: [String]) -> [Correction] {
        queuedFatalError("Must call `correct(file:collectedInfo:compilerArguments:)` for AnalyzerRule")
    }
    func correct(file: File, collectedInfo: [File: FileInfo]) -> [Correction] {
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
