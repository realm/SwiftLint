public struct RuleDescription: Equatable, Codable {
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

    // MARK: Codable

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.identifier = try container.decode(String.self, forKey: .identifier)
        self.name = try container.decode(String.self, forKey: .name)
        self.description = try container.decode(String.self, forKey: .description)
        self.kind = try container.decode(RuleKind.self, forKey: .kind)
        self.nonTriggeringExamples = container.optionalDecode([String].self, forKey: .nonTriggeringExamples) ?? []
        self.triggeringExamples = container.optionalDecode([String].self, forKey: .triggeringExamples) ?? []
        self.corrections = container.optionalDecode([String: String].self, forKey: .corrections) ?? [:]
        self.deprecatedAliases = container.optionalDecode(Set<String>.self, forKey: .deprecatedAliases) ?? []
        self.minSwiftVersion = container.optionalDecode(SwiftVersion.self, forKey: .minSwiftVersion) ?? .three
        self.requiresFileOnDisk = container.optionalDecode(Bool.self, forKey: .requiresFileOnDisk) ?? false
    }
}

private extension KeyedDecodingContainerProtocol {
    func optionalDecode<T>(_ type: T.Type, forKey key: KeyedDecodingContainer<Key>.Key) -> T? where T: Decodable {
        do {
            return try decodeIfPresent(type, forKey: key)
        } catch {
            return nil
        }
    }
}
