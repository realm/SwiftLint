import SourceKittenFramework

private enum VariableKind: String {
    case instance
    case local
    case `static`
    case `class`
}

private extension SwiftDeclarationKind {
    init(variableKind: VariableKind) {
        switch variableKind {
        case .instance:
            self = .varInstance
        case .local:
            self = .varLocal
        case .static:
            self = .varStatic
        case .class:
            self = .varClass
        }
    }

    var variableKind: VariableKind? {
        switch self {
        case .varInstance:
            return .instance
        case .varLocal:
            return .local
        case .varStatic:
            return .static
        case .varClass:
            return .class
        default:
            return nil
        }
    }
}

struct ExplicitTypeInterfaceConfiguration: RuleConfiguration, Equatable {
    private static let variableKinds: Set<SwiftDeclarationKind> = [.varInstance,
                                                                   .varLocal,
                                                                   .varStatic,
                                                                   .varClass]

    private(set) var severityConfiguration = SeverityConfiguration(.warning)

    private(set) var allowedKinds = Self.variableKinds

    private(set) var allowRedundancy = false

    var consoleDescription: String {
        let excludedKinds = Self.variableKinds.subtracting(allowedKinds)
        let simplifiedExcludedKinds = excludedKinds.compactMap { $0.variableKind?.rawValue }.sorted()
        return severityConfiguration.consoleDescription +
            ", excluded: \(simplifiedExcludedKinds)" +
            ", allow_redundancy: \(allowRedundancy)"
    }

    init() {}

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }
        for (key, value) in configuration {
            switch (key, value) {
            case ("severity", let severityString as String):
                try severityConfiguration.apply(configuration: severityString)
            case ("excluded", let excludedStrings as [String]):
                let excludedKinds = excludedStrings.compactMap(VariableKind.init(rawValue:))
                allowedKinds.subtract(excludedKinds.map(SwiftDeclarationKind.init(variableKind:)))
            case ("allow_redundancy", let allowRedundancy as Bool):
                self.allowRedundancy = allowRedundancy
            default:
                throw ConfigurationError.unknownConfiguration
            }
        }
    }
}
