import Foundation
import SourceKittenFramework

public protocol Rule {
    static var description: RuleDescription { get }
    var configurationDescription: String { get }

    init() // Rules need to be able to be initialized with default values
    init(configuration: Any) throws

    // Storage methods always have provided implementations of these
    func collect(infoFor file: File, into storage: inout RuleStorage)
    func validate(file: File, using storage: RuleStorage) -> [StyleViolation]
    func validate(file: File, using storage: RuleStorage, compilerArguments: [String]) -> [StyleViolation]

    func validate(file: File, compilerArguments: [String]) -> [StyleViolation]
    func validate(file: File) -> [StyleViolation]
    func isEqualTo(_ rule: Rule) -> Bool
}

extension Rule {
    public func collect(infoFor file: File, into storage: inout RuleStorage) {
        // Only CollectingRules mutate their storage
    }

    public func validate(file: File, using storage: RuleStorage, compilerArguments: [String]) -> [StyleViolation] {
        return validate(file: file, compilerArguments: compilerArguments)
    }

    public func validate(file: File, using storage: RuleStorage) -> [StyleViolation] {
        return validate(file: file)
    }

    public func validate(file: File, compilerArguments: [String]) -> [StyleViolation] {
        return validate(file: file)
    }

    public func isEqualTo(_ rule: Rule) -> Bool {
        return type(of: self).description == type(of: rule).description
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
    func correct(file: File, using storage: RuleStorage, compilerArguments: [String]) -> [Correction]
    func correct(file: File, using storage: RuleStorage) -> [Correction]
}

public extension CorrectableRule {
    func correct(file: File, compilerArguments: [String]) -> [Correction] {
        return correct(file: file)
    }
    func correct(file: File, using storage: RuleStorage) -> [Correction] {
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
                         dictionary: [String: SourceKitRepresentable]) -> [NSRange]
}

extension SubstitutionCorrectableASTRule where KindType.RawValue == String {
    public func violationRanges(in file: File) -> [NSRange] {
        return violationRanges(in: file, dictionary: file.structure.dictionary)
    }

    private func violationRanges(in file: File,
                                 dictionary: [String: SourceKitRepresentable]) -> [NSRange] {
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

// MARK: - CollectingRule

public protocol CollectingRule: Rule {
    associatedtype FileInfo
    func collect(file: File) -> FileInfo
    func validate(fileInfo: [FileInfo], compilerArguments: [String]) -> [StyleViolation]
    func validate(fileInfo: [FileInfo]) -> [StyleViolation]
}

public extension CollectingRule {
    func collect(infoFor file: File, into storage: inout RuleStorage) {
        storage.collect(info: collect(file: file), for: self)
    }
    func validate(fileInfo: [FileInfo], compilerArguments: [String]) -> [StyleViolation] {
        return validate(fileInfo: fileInfo)
    }

    func validate(file: File) -> [StyleViolation] {
        queuedFatalError("Must call `validate(fileInfo:)` for CollectingRule")
    }
}

public extension CollectingRule where Self: AnalyzerRule {
    func validate(file: File, compilerArguments: [String]) -> [StyleViolation] {
        queuedFatalError("Must call `validate(fileInfo:compilerArguments:)` for AnalyzerPassing")
    }
}

public protocol CollectingCorrectableRule: CollectingRule {
    // TODO actually call these
    func correct(fileInfo: [FileInfo], compilerArguments: [String]) -> [Correction]
    func correct(fileInfo: [FileInfo]) -> [Correction]
}

public extension CollectingCorrectableRule {
    func correct(fileInfo: [FileInfo], compilerArguments: [String]) -> [Correction] {
        return correct(fileInfo: fileInfo)
    }
}

public extension CollectingCorrectableRule where Self: AnalyzerRule {
    func correct(fileInfo: [FileInfo]) -> [Correction] {
        queuedFatalError("Must call `correct(fileInfo:compilerArguments:)` for AnalyzerPassingCorrectableRule")
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
