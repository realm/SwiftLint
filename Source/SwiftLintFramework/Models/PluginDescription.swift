public enum PluginRequiredInput: String, Codable {
    case syntaxMap = "syntax_map"
    case structure = "structure"
}

public struct PluginDescription: Equatable, Codable {
    public let ruleDescription: RuleDescription
    public let requiredInformation: Set<PluginRequiredInput>

    public init(ruleDescription: RuleDescription,
                requiredInformation: Set<PluginRequiredInput> = []) {
        self.ruleDescription = ruleDescription
        self.requiredInformation = requiredInformation
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.ruleDescription = try container.decode(RuleDescription.self, forKey: .ruleDescription)
        self.requiredInformation = try container.decodeIfPresent(Set<PluginRequiredInput>.self,
                                                                 forKey: .requiredInformation) ?? []
    }
}
