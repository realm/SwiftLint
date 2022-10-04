public struct ObjectLiteralConfiguration: SeverityBasedRuleConfiguration, Equatable {
    public private(set) var severityConfiguration = SeverityConfiguration(.warning)
    private(set) var imageLiteral = true
    private(set) var colorLiteral = true

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription
            + ", image_literal: \(imageLiteral)"
            + ", color_literal: \(colorLiteral)"
    }

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        imageLiteral = configuration["image_literal"] as? Bool ?? true
        colorLiteral = configuration["color_literal"] as? Bool ?? true

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
