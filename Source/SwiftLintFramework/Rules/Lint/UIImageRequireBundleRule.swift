public struct UIImageRequireBundleRule: ASTRule, OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "uiimage_require_bundle",
        name: "UIImage Require Bundle",
        description: "Calls to UIImage(named:) should specify the bundle which contains the strings file.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
			UIImage(named: "someImage", in: .main, compatibleWith: nil)
			"""),
            Example("""
			UIImage(named: "someImage",
					in: .main,
					compatibleWith: nil)
			"""),
            Example("""
			UIImage(contentsOfFile: filePath)
			"""),
            Example("""
			UIImage()
			"""),
            Example("""
			UIImage.init()
			""")
        ],
        triggeringExamples: [
            Example("""
			↓UIImage(named: "someImage")
			"""),
            Example("""
			↓UIImage.init(named: "someImage")
			""")
        ]
    )

    public func validate(file: SwiftLintFile,
                         kind: SwiftExpressionKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        let isNamedArgument: (SourceKittenDictionary) -> Bool = { $0.name == "named" }
        let isBundleArgument: (SourceKittenDictionary) -> Bool = { $0.name == "in" }
        guard kind == .call,
			  dictionary.name == "UIImage" || dictionary.name == "UIImage.init",
              let offset = dictionary.offset,
              !dictionary.enclosedArguments.contains(where: isBundleArgument),
              dictionary.enclosedArguments.contains(where: isNamedArgument) else {
            return []
        }
        return [
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: offset))
        ]
    }
}
