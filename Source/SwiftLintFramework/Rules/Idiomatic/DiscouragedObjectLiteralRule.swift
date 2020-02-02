public struct DiscouragedObjectLiteralRule: ASTRule, OptInRule, ConfigurationProviderRule {
    public var configuration = ObjectLiteralConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "discouraged_object_literal",
        name: "Discouraged Object Literal",
        description: "Prefer initializers over object literals.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("let image = UIImage(named: aVariable)"),
            Example("let image = UIImage(named: \"interpolated \\(variable)\")"),
            Example("let color = UIColor(red: value, green: value, blue: value, alpha: 1)"),
            Example("let image = NSImage(named: aVariable)"),
            Example("let image = NSImage(named: \"interpolated \\(variable)\")"),
            Example("let color = NSColor(red: value, green: value, blue: value, alpha: 1)")
        ],
        triggeringExamples: [
            Example("let image = ↓#imageLiteral(resourceName: \"image.jpg\")"),
            Example("let color = ↓#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)")
        ]
    )

    public func validate(file: SwiftLintFile,
                         kind: SwiftExpressionKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard let offset = dictionary.offset, kind == .objectLiteral else { return [] }

        if !configuration.imageLiteral && dictionary.name == "imageLiteral" {
            return []
        }

        if !configuration.colorLiteral && dictionary.name == "colorLiteral" {
            return []
        }

        return [StyleViolation(ruleDescription: type(of: self).description,
                               severity: configuration.severityConfiguration.severity,
                               location: Location(file: file, byteOffset: offset))]
    }
}
