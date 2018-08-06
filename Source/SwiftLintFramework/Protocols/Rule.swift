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

public protocol SourceKitFreeRule: Rule {}

public protocol CompilerArgumentRule: Rule {}

public extension CompilerArgumentRule {
    func validate(file: File) -> [StyleViolation] {
        return validate(file: file, compilerArguments: [])
    }
}

public extension CompilerArgumentRule where Self: CorrectableRule {
    func correct(file: File) -> [Correction] {
        return correct(file: file, compilerArguments: [])
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

public func == (lhs: [Rule], rhs: [Rule]) -> Bool {
    if lhs.count != rhs.count { return false }
    return !zip(lhs, rhs).contains { !$0.0.isEqualTo($0.1) }
}
