import Foundation
import SourceKittenFramework

public struct MultilineClosureAnonymousArgsRule: ConfigurationProviderRule, OptInRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public static let description = RuleDescription(
        identifier: "multiline_closure_anonymous_args",
        name: "Multiline Closure Anonymous Arguments",
        description: "Multiline closures should use named argmuents.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("{ print($0 }"),
            Example("{\nprint(array.map { $0.property }\n}"),
            Example("// print($0)"),
            Example("\"$0.00\"")
        ],
        triggeringExamples: [
            Example("{\nprint($0)\n}"),
            Example("$0.numberOfLines = 0\n$0.textColor = .secondaryLabel"),
            Example("array.compactMap($0)")
        ]
    )

    public init() {}

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        return file.match(
            pattern: "^[^{\\n]*(\\$0)",
            excludingSyntaxKinds: SyntaxKind.commentAndStringKinds
        ).compactMap { range in
            return StyleViolation(
                ruleDescription: Self.description,
                severity: configuration.severity,
                location: Location(file: file, characterOffset: range.location)
            )
        }
    }
}
