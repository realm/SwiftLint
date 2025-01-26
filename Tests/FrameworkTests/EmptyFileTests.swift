import SwiftLintFramework
import XCTest

private protocol BooleanConstant {
    static var boolValue: Bool { get }
}

private struct True: BooleanConstant {
    static var boolValue: Bool { true }
}

private struct False: BooleanConstant {
    static var boolValue: Bool { false }
}

private struct RuleWithLintEmptyFilesMock<ShouldLintEmptyFiles: BooleanConstant>: CorrectableRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static var description: RuleDescription {
        RuleDescription(identifier: "lint_empty_files_mock<\(ShouldLintEmptyFiles.boolValue)>",
                        name: "",
                        description: "",
                        kind: .style,
                        deprecatedAliases: ["mock"])
    }

    init() { /* conformance for test */ }
    init(configuration _: Any) throws {
        self.init()
    }

    var shouldLintEmptyFiles: Bool {
        ShouldLintEmptyFiles.boolValue
    }

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        [
            StyleViolation(ruleDescription: Self.description, location: Location(file: file.path))
        ]
    }

    func correct(file: SwiftLintFile) -> [Correction] {
        [
            Correction(ruleDescription: Self.description, location: Location(file: file.path))
        ]
    }
}

final class EmptyFileTests: SwiftLintTestCase {
    func testShouldLintEmptyFileRespectedDuringLint() {
        let ruleList = RuleList(rules: RuleWithLintEmptyFilesMock<False>.self,
                                RuleWithLintEmptyFilesMock<True>.self)
        let configuration = try! Configuration(dict: [:], ruleList: ruleList) // swiftlint:disable:this force_try
        let file = SwiftLintFile(contents: "")
        let linter = Linter(file: file, configuration: configuration)
        let ruleStorage = RuleStorage()
        let collectedLinter = linter.collect(into: ruleStorage)
        let styleViolations = collectedLinter.styleViolations(using: ruleStorage)
        XCTAssertEqual(styleViolations.count, 1)
        XCTAssertEqual(styleViolations.first?.ruleIdentifier, "lint_empty_files_mock<true>")
    }

    func testShouldLintEmptyFileRespectedDuringCorrect() {
        let ruleList = RuleList(rules: RuleWithLintEmptyFilesMock<False>.self,
                                RuleWithLintEmptyFilesMock<True>.self)
        let configuration = try! Configuration(dict: [:], ruleList: ruleList) // swiftlint:disable:this force_try
        let file = SwiftLintFile(contents: "")
        let linter = Linter(file: file, configuration: configuration)
        let ruleStorage = RuleStorage()
        let collectedLinter = linter.collect(into: ruleStorage)
        let corrections = collectedLinter.correct(using: ruleStorage)
        XCTAssertEqual(corrections.count, 1)
        XCTAssertEqual(corrections.first?.ruleDescription.identifier, "lint_empty_files_mock<true>")
    }
}
