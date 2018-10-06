import Foundation
import SourceKittenFramework

public struct LegacyRandomRule: OptInRule, ConfigurationProviderRule, AutomaticTestableRule {

    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static var description = RuleDescription(
        identifier: "legacy_random",
        name: "Legacy Random",
        description: "Prefer using `type.random(in:)` over legacy functions.",
        kind: .idiomatic,
        minSwiftVersion: .fourDotTwo,
        nonTriggeringExamples: [
            "Int.random(in: 0..<10)\n",
            "Double.random(in: 8.6...111.34)\n",
            "Float.random(in: 0 ..< 1)\n"
        ],
        triggeringExamples: [
            "↓arc4random(10)\n",
            "↓arc4random_uniform(83)\n",
            "↓drand48(52)\n"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        let pattern = "(arc4random|drand48)"
        let excludingKinds = SyntaxKind.commentAndStringKinds

        return file.match(pattern: pattern, excludingSyntaxKinds: excludingKinds).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }
}
