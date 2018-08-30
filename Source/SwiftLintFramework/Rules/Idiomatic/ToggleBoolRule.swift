import SourceKittenFramework

public struct ToggleBoolRule: ConfigurationProviderRule, OptInRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static var description = RuleDescription(
        identifier: "toggle_bool",
        name: "Toggle Bool",
        description: "Prefer `Bool.toggle()` over `someBool = !someBool`.",
        kind: .idiomatic,
        minSwiftVersion: .fourDotTwo,
        nonTriggeringExamples: [
            "isHidden.toggle()\n",
            "view.clipsToBounds.toggle()\n",
            "func foo() { abc.toggle() }"
        ],
        triggeringExamples: [
            "isHidden = ↓!isHidden\n",
            "view.clipsToBounds = ↓!view.clipsToBounds\n",
            "func foo() { abc = ↓!abc }"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        let pattern = "\\b([\\w.]+) = !\\1\\b"
        let excludingKinds = SyntaxKind.commentAndStringKinds
        return file.match(pattern: pattern, excludingSyntaxKinds: excludingKinds).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }
}
