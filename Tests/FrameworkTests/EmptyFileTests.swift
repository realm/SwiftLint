import SwiftLintFramework
import XCTest

// swiftlint:disable:next balanced_xctest_lifecycle
final class EmptyFileTests: SwiftLintTestCase {
    var collectedLinter: CollectedLinter! // swiftlint:disable:this implicitly_unwrapped_optional
    var ruleStorage: RuleStorage! // swiftlint:disable:this implicitly_unwrapped_optional

    override func setUpWithError() throws {
        let ruleList = RuleList(rules: RuleMock<DontLintEmptyFiles>.self, RuleMock<LintEmptyFiles>.self)
        let configuration = try Configuration(dict: [:], ruleList: ruleList)
        let file = SwiftLintFile(contents: "")
        let linter = Linter(file: file, configuration: configuration)
        ruleStorage = RuleStorage()
        collectedLinter = linter.collect(into: ruleStorage)
    }

    func testShouldLintEmptyFileRespectedDuringLint() throws {
        let styleViolations = collectedLinter.styleViolations(using: ruleStorage)
        XCTAssertEqual(styleViolations.count, 1)
        XCTAssertEqual(styleViolations.first?.ruleIdentifier, "rule_mock<LintEmptyFiles>")
    }

    func testShouldLintEmptyFileRespectedDuringCorrect() throws {
        let corrections = collectedLinter.correct(using: ruleStorage)
        XCTAssertEqual(corrections, ["rule_mock<LintEmptyFiles>": 1])
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

private struct RuleMock<ShouldLintEmptyFiles: ShouldLintEmptyFilesProtocol>: CorrectableRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static var description: RuleDescription {
        RuleDescription(identifier: "rule_mock<\(ShouldLintEmptyFiles.self)>",
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
