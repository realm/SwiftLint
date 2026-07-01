import SwiftLintCore
import SwiftLintFramework
import TestHelpers
import Testing

@Suite(.rulesRegistered)
struct GlobalConfigurationTests {
    // MARK: - Bridge: Configuration -> GlobalConfiguration

    @Test(arguments: [
        IndentationStyle.tabs,
        IndentationStyle.spaces(count: 2),
        IndentationStyle.spaces(count: 4),
    ])
    func bridgeMapsIndentation(_ indentation: IndentationStyle) {
        let configuration = Configuration(indentation: indentation)
        #expect(configuration.globalConfiguration.indentation == indentation)
    }

    @Test
    func bridgeMapsDefaultIndentationWhenNotSpecified() {
        let configuration = Configuration()
        #expect(configuration.globalConfiguration.indentation == .default)
    }

    @Test
    func configurationIsNilOutsideLinterContext() {
        #expect(CurrentRule.configuration == nil)
    }

    // MARK: - End-to-end: CurrentRule.configuration is propagated to validate

    /// Emits a violation whose reason encodes the indentation observed via `CurrentRule.configuration`.
    private struct GlobalIndentationDummyRule: SourceKitFreeRule {
        var configuration = SeverityConfiguration<Self>(.warning)
        var configurationDescription: some Documentable { RuleConfigurationOption.noOptions }

        static let description = RuleDescription(
            identifier: "global_indentation_dummy",
            name: "",
            description: "",
            kind: .style
        )

        init() { /* conformance for test */ }
        init(configuration _: Any) { self.init() }

        func validate(file: SwiftLintFile) -> [StyleViolation] {
            let indentation = CurrentRule.configuration?.indentation
            let reason: String
            switch indentation {
            case .tabs: reason = "tabs"
            case .spaces(let count): reason = "spaces(\(count))"
            case nil: reason = "nil"
            }
            return [
                StyleViolation(
                    ruleDescription: Self.description,
                    severity: .warning,
                    location: Location(file: file.path, line: 1, character: 1),
                    reason: reason
                ),
            ]
        }
    }

    private func dummyReason(indentation: IndentationStyle) -> String {
        let ruleList = RuleList(rules: GlobalIndentationDummyRule.self)
        let configuration = Configuration(
            rulesMode: .onlyConfiguration([GlobalIndentationDummyRule.identifier]),
            ruleList: ruleList,
            indentation: indentation
        )
        let file = SwiftLintFile(contents: "let x = 0\n")
        let storage = RuleStorage()
        let linter = Linter(file: file, configuration: configuration).collect(into: storage)
        return linter.styleViolations(using: storage).first?.reason ?? "no violations"
    }

    @Test(arguments: [
        (indentation: IndentationStyle.tabs, expected: "tabs"),
        (indentation: IndentationStyle.spaces(count: 2), expected: "spaces(2)"),
        (indentation: IndentationStyle.spaces(count: 4), expected: "spaces(4)"),
    ])
    func ruleObservesIndentation(indentation: IndentationStyle, expected: String) {
        #expect(dummyReason(indentation: indentation) == expected)
    }

    @Test
    func differentConfigurationsDoNotLeakBetweenLints() {
        #expect(dummyReason(indentation: .tabs) == "tabs")
        #expect(dummyReason(indentation: .spaces(count: 2)) == "spaces(2)")
    }

    @Test
    func linterConfigurationShadowsOuterTaskLocalAndRestoresAfter() {
        let outerConfig = GlobalConfiguration(indentation: .spaces(count: 8))

        let reason = CurrentRule.$configuration.withValue(outerConfig) {
            #expect(CurrentRule.configuration?.indentation == .spaces(count: 8))
            let result = dummyReason(indentation: .tabs)
            #expect(CurrentRule.configuration?.indentation == .spaces(count: 8))
            return result
        }

        #expect(reason == "tabs")
        #expect(CurrentRule.configuration == nil)
    }
}
