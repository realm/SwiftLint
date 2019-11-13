import Foundation
import SourceKittenFramework

public struct ToggleBoolRule: SubstitutionCorrectableRule, ConfigurationProviderRule, OptInRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static var description = RuleDescription(
        identifier: "toggle_bool",
        name: "Toggle Bool",
        description: "Prefer `someBool.toggle()` over `someBool = !someBool`.",
        kind: .idiomatic,
        minSwiftVersion: .fourDotTwo,
        nonTriggeringExamples: [
            "isHidden.toggle()\n",
            "view.clipsToBounds.toggle()\n",
            "func foo() { abc.toggle() }",
            "view.clipsToBounds = !clipsToBounds\n",
            "disconnected = !connected\n"
        ],
        triggeringExamples: [
            "↓isHidden = !isHidden\n",
            "↓view.clipsToBounds = !view.clipsToBounds\n",
            "func foo() { ↓abc = !abc }"
        ],
        corrections: [
            "↓isHidden = !isHidden\n": "isHidden.toggle()\n",
            "↓view.clipsToBounds = !view.clipsToBounds\n": "view.clipsToBounds.toggle()\n",
            "func foo() { ↓abc = !abc }": "func foo() { abc.toggle() }"
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        return violationRanges(in: file).map {
            StyleViolation(ruleDescription: ToggleBoolRule.description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location)
            )
        }
    }

    public func violationRanges(in file: SwiftLintFile) -> [NSRange] {
        let pattern = "(?<![\\w.])([\\w.]+) = !\\1\\b"
        let excludingKinds = SyntaxKind.commentAndStringKinds
        return file.match(pattern: pattern, excludingSyntaxKinds: excludingKinds)
    }

    public func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String) {
        let violationString = file.linesContainer.substring(with: violationRange)
        let identifier = violationString.components(separatedBy: .whitespaces).first { !$0.isEmpty }
        return (violationRange, identifier! + ".toggle()")
    }
}
