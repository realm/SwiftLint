import Foundation
import SwiftLintFramework
import TestHelpers
import Testing

@Suite
struct EmptyFileTests {
    var collectedLinter: CollectedLinter!  // swiftlint:disable:this implicitly_unwrapped_optional
    var ruleStorage: RuleStorage!  // swiftlint:disable:this implicitly_unwrapped_optional

    init() throws {
        let ruleList = RuleList(
            rules: RuleMock<DontLintEmptyFiles>.self,
            RuleMock<LintEmptyFiles>.self,
            RuleMock<UnsupportedSwiftVersion>.self
        )
        let configuration = try Configuration(dict: [:], ruleList: ruleList)
        let file = SwiftLintFile(contents: "")
        let linter = Linter(file: file, configuration: configuration)
        ruleStorage = RuleStorage()
        collectedLinter = linter.collect(into: ruleStorage)
    }

    @Test
    func shouldLintEmptyFileRespectedDuringLint() {
        let styleViolations = collectedLinter.styleViolations(using: ruleStorage)
        #expect(styleViolations.count == 1)
        #expect(styleViolations.first?.ruleIdentifier == "rule_mock<LintEmptyFiles>")
    }

    @Test
    func shouldLintEmptyFileRespectedDuringCorrect() {
        let corrections = collectedLinter.correct(using: ruleStorage)
        #expect(corrections == ["rule_mock<LintEmptyFiles>": 1])
    }

    @Test(.parserDiagnosticsEnabled(false))
    func unsupportedRuleDoesNotReadFileDuringCorrect() throws {
        let ruleList = RuleList(rules: RuleMock<UnsupportedSwiftVersion>.self)
        let configuration = try Configuration(dict: [:], ruleList: ruleList)
        let missingFile = URL.temporaryDirectory
            .appending(path: UUID().uuidString)
            .appendingPathExtension("swift")
        let file = SwiftLintFile(pathDeferringReading: missingFile)
        let storage = RuleStorage()
        let collectedLinter = Linter(file: file, configuration: configuration).collect(into: storage)

        #expect(collectedLinter.correct(using: storage).isEmpty)
    }
}

private protocol RuleMockBehavior {
    static var shouldLintEmptyFiles: Bool { get }
    static var minSwiftVersion: SwiftVersion { get }
}

private extension RuleMockBehavior {
    static var minSwiftVersion: SwiftVersion { .five }
}

private struct LintEmptyFiles: RuleMockBehavior {
    static var shouldLintEmptyFiles: Bool { true }
}

private struct DontLintEmptyFiles: RuleMockBehavior {
    static var shouldLintEmptyFiles: Bool { false }
}

private struct UnsupportedSwiftVersion: RuleMockBehavior {
    static var shouldLintEmptyFiles: Bool { false }
    static var minSwiftVersion: SwiftVersion { SwiftVersion(rawValue: "999.0.0") }
}

private struct RuleMock<Behavior: RuleMockBehavior>: CorrectableRule, SourceKitFreeRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static var description: RuleDescription {
        RuleDescription(
            identifier: "rule_mock<\(Behavior.self)>",
            name: "",
            description: "",
            kind: .style,
            minSwiftVersion: Behavior.minSwiftVersion,
            deprecatedAliases: ["mock"])
    }

    var shouldLintEmptyFiles: Bool {
        Behavior.shouldLintEmptyFiles
    }

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        [StyleViolation(ruleDescription: Self.description, location: Location(file: file.path))]
    }

    func correct(file _: SwiftLintFile) -> Int {
        1
    }
}
