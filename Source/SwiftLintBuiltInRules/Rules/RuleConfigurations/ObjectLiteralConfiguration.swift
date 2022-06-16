typealias DiscouragedObjectLiteralConfiguration = ObjectLiteralConfiguration<DiscouragedObjectLiteralRule>

struct ObjectLiteralConfiguration<Parent: Rule>: SeverityBasedRuleConfiguration, Equatable {
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    private(set) var imageLiteral = true
    private(set) var colorLiteral = true

    var parameterDescription: RuleConfigurationDescription? {
        severityConfiguration
        "image_literal" => .flag(imageLiteral)
        "color_literal" => .flag(colorLiteral)
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        imageLiteral = configuration["image_literal"] as? Bool ?? true
        colorLiteral = configuration["color_literal"] as? Bool ?? true

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
