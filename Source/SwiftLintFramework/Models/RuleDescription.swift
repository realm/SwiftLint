public struct RuleDescription: Equatable {
    public let identifier: String
    public let name: String
    public let description: String
    public let kind: RuleKind
    public let nonTriggeringExamples: [String]
    public let triggeringExamples: [String]
    public let corrections: [String: String]
    public let deprecatedAliases: Set<String>
    public let minSwiftVersion: SwiftVersion
    public let requiresFileOnDisk: Bool

    public var consoleDescription: String { return "\(name) (\(identifier)): \(description)" }

    public var allIdentifiers: [String] {
        return Array(deprecatedAliases) + [identifier]
    }

    public init(identifier: String, name: String, description: String, kind: RuleKind,
                minSwiftVersion: SwiftVersion = .three,
                nonTriggeringExamples: [String] = [], triggeringExamples: [String] = [],
                corrections: [String: String] = [:],
                deprecatedAliases: Set<String> = [],
                requiresFileOnDisk: Bool = false) {
        self.identifier = identifier
        self.name = name
        self.description = description
        self.kind = kind
        self.nonTriggeringExamples = nonTriggeringExamples
        self.triggeringExamples = triggeringExamples
        self.corrections = corrections
        self.deprecatedAliases = deprecatedAliases
        self.minSwiftVersion = minSwiftVersion
        self.requiresFileOnDisk = requiresFileOnDisk
    }

    // MARK: Equatable

    public static func == (lhs: RuleDescription, rhs: RuleDescription) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}
