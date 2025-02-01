import SwiftLintFramework
import Testing

@Suite
struct EmptyFileTests {
    var collectedLinter: CollectedLinter!  // swiftlint:disable:this implicitly_unwrapped_optional
    var ruleStorage: RuleStorage!  // swiftlint:disable:this implicitly_unwrapped_optional

    init() throws {
        let ruleList = RuleList(rules: RuleMock<DontLintEmptyFiles>.self, RuleMock<LintEmptyFiles>.self)
        let configuration = try Configuration(dict: [:], ruleList: ruleList)
        let file = SwiftLintFile(contents: "")
        let linter = Linter(file: file, configuration: configuration)
        ruleStorage = RuleStorage()
        collectedLinter = linter.collect(into: ruleStorage)
    }

    @Test
    func shouldLintEmptyFileRespectedDuringLint() throws {
        let styleViolations = collectedLinter.styleViolations(using: ruleStorage)
        #expect(styleViolations.count == 1)
        #expect(styleViolations.first?.ruleIdentifier == "rule_mock<LintEmptyFiles>")
    }

    @Test
    func shouldLintEmptyFileRespectedDuringCorrect() throws {
        let corrections = collectedLinter.correct(using: ruleStorage)
        #expect(corrections == ["rule_mock<LintEmptyFiles>": 1])
    }
}

private protocol ShouldLintEmptyFilesProtocol {
    static var shouldLintEmptyFiles: Bool { get }
}

private struct LintEmptyFiles: ShouldLintEmptyFilesProtocol {
    static var shouldLintEmptyFiles: Bool { true }
}

private struct DontLintEmptyFiles: ShouldLintEmptyFilesProtocol {
    static var shouldLintEmptyFiles: Bool { false }
}

private struct RuleMock<ShouldLintEmptyFiles: ShouldLintEmptyFilesProtocol>: CorrectableRule, SourceKitFreeRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static var description: RuleDescription {
        RuleDescription(
            identifier: "rule_mock<\(ShouldLintEmptyFiles.self)>",
            name: "",
            description: "",
            kind: .style,
            deprecatedAliases: ["mock"])
    }

    var shouldLintEmptyFiles: Bool {
        ShouldLintEmptyFiles.shouldLintEmptyFiles
    }

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        [StyleViolation(ruleDescription: Self.description, location: Location(file: file.path))]
    }

    func correct(file _: SwiftLintFile) -> Int {
        1
    }
}
