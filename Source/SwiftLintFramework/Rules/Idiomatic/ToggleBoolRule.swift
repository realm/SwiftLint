import Foundation
import SourceKittenFramework

public struct ToggleBoolRule: SubstitutionCorrectableRule, ConfigurationProviderRule, OptInRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static var description = RuleDescription(
        identifier: "toggle_bool",
        name: "Toggle Bool",
        description: "Prefer `someBool.toggle()` over `someBool = !someBool`.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("isHidden.toggle()\n"),
            Example("view.clipsToBounds.toggle()\n"),
            Example("func foo() { abc.toggle() }"),
            Example("view.clipsToBounds = !clipsToBounds\n"),
            Example("disconnected = !connected\n"),
            Example("result = !result.toggle()")
        ],
        triggeringExamples: [
            Example("↓isHidden = !isHidden\n"),
            Example("↓view.clipsToBounds = !view.clipsToBounds\n"),
            Example("func foo() { ↓abc = !abc }")
        ],
        corrections: [
            Example("↓isHidden = !isHidden\n"): Example("isHidden.toggle()\n"),
            Example("↓view.clipsToBounds = !view.clipsToBounds\n"): Example("view.clipsToBounds.toggle()\n"),
            Example("func foo() { ↓abc = !abc }"): Example("func foo() { abc.toggle() }")
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        return violationRanges(in: file).map {
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location)
            )
        }
    }

    public func violationRanges(in file: SwiftLintFile) -> [NSRange] {
        let pattern = #"(?<![\w.])([\w.]+) = !\1\b(?!\.)"#
        let excludingKinds = SyntaxKind.commentAndStringKinds
        return file.match(pattern: pattern, excludingSyntaxKinds: excludingKinds)
    }

    public func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String)? {
        let violationString = file.stringView.substring(with: violationRange)
        let identifier = violationString.components(separatedBy: .whitespaces).first { $0.isNotEmpty }
        return (violationRange, identifier! + ".toggle()")
    }
}
