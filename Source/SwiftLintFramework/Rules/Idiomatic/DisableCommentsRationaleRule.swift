import Foundation
import SourceKittenFramework

public struct DisableCommentsRationaleRule: OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() { }

    private static let nonTriggeringExamples = [
        """
        // Force unwrapping is used here, because initializing it with the github domain can not fail
        // swiftlint:disable force_unwrapping

        let url = URL(string: "https://github.com")!
        """,
        """
        // swiftlint:disable force_unwrapping
        // Force unwrapping is used here, because initializing it with the github domain can not fail

        let url = URL(string: "https://github.com")!
        """,
        """
            // Force unwrapping is used here, because initializing it with the github domain can not fail
                // swiftlint:disable force_unwrapping

        let url = URL(string: "https://github.com")!
        """,
        """
        // Force unwrapping is used here, because initializing it with the github domain can not fail
        let url = URL(string: "https://github.com")! // swiftlint:disable:this force_unwrapping
        """,
        """
        let url = URL(string: "https://github.com")! // swiftlint:disable:this force_unwrapping
        // Force unwrapping is used here, because initializing it with the github domain can not fail
        """,
        """
        // Force unwrapping is used here, because initializing it with the github domain can not fail
        // swiftlint:disable:next force_unwrapping
        let url = URL(string: "https://github.com")!
        """,
        """
        let url = URL(string: "https://github.com")!
        // swiftlint:disable:previous force_unwrapping
        // Force unwrapping is used here, because initializing it with the github domain can not fail
        """,
        // For now, this is failing
        """
        let string = "let url = URL(string: "https://github.com")! // swiftlint:disable:this force_unwrapping"
        """
    ]

    private static let triggeringExamples = [
        """
        ↓// swiftlint:disable force_unwrapping
        let url = URL(string: "https://github.com")!
        """,
        """
        ↓// swiftlint:disable:next force_unwrapping
        let url = URL(string: "https://github.com")!
        """,
        """
        ↓let url = URL(string: "https://github.com")! // swiftlint:disable:this force_unwrapping
        """,
        """
        let url = URL(string: "https://github.com")!
        ↓// swiftlint:disable:previous force_unwrapping
        """
    ]

    public static let description = RuleDescription(
        identifier: "disable_comments_rationale",
        name: "Disable Comments Rationale",
        description: "When disabling a rule, the rationale should be added as a comment in the previous or  line.",
        kind: .idiomatic,
        nonTriggeringExamples: nonTriggeringExamples,
        triggeringExamples: triggeringExamples
    )

    public func validate(file: File) -> [StyleViolation] {
        let disableMatches = file.match(pattern: "swiftlint:disable", with: [.comment])
        guard disableMatches.isEmpty == false else {
            return []
        }

        let lines = file.lines
        return disableMatches.compactMap { violationRange in
            guard let line = file.contents.bridge()
                .lineAndCharacter(forCharacterOffset: violationRange.location)?.line else {
                queuedFatalError("A disable command was found, but its line number could not be obtained")
            }

            let lineIndex = line - 1
            let surroundLineIndices = [lineIndex - 1, lineIndex + 1]
            for lineIndex in surroundLineIndices {
                guard lines.indices.contains(lineIndex) else {
                    continue
                }

                if lines[lineIndex].content.trimmingCharacters(in: .whitespaces).hasPrefix("//") {
                    return nil
                }
            }

            let lineRange = file.contents.bridge().lineRange(for: violationRange)
            return StyleViolation(
                ruleDescription: type(of: self).description,
                severity: configuration.severity,
                location: Location(file: file, characterOffset: lineRange.location)
            )
        }
    }
}
