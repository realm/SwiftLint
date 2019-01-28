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
}

extension Rule {
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
}

public extension CorrectableRule {
    func correct(file: File, compilerArguments: [String]) -> [Correction] {
        return correct(file: file)
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

// MARK: - ConfigurationProviderRule conformance to Configurable

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
