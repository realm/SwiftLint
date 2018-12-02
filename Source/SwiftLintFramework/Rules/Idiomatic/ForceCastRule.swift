import SourceKittenFramework

public struct ForceCastRule: ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.error)

    public init() {}

    public static let description = RuleDescription(
        identifier: "force_cast",
        name: "Force Cast",
        description: "Force casts should be avoided.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            "NSNumber() as? Int\n"
        ],
        triggeringExamples: [ "NSNumber() ↓as! Int\n" ]
    )

    public func validate(file: File) -> [StyleViolation] {
        return file.match(pattern: "as!", with: [.keyword]).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }
}
