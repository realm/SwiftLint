import Foundation
import SourceKittenFramework
import TestHelpers
import Testing

@testable import SwiftLintFramework

@Suite
struct CollectingRuleTests {
    @Test
    func collectsIntoStorage() {
        struct Spec: MockCollectingRule {
            var configuration = SeverityConfiguration<Self>(.warning)

            func collectInfo(for _: SwiftLintFile) -> Int {
                42
            }

            func validate(file: SwiftLintFile, collectedInfo: [SwiftLintFile: Int]) -> [StyleViolation] {
                #expect(collectedInfo[file] == 42)
                return [
                    StyleViolation(
                        ruleDescription: Self.description,
                        location: Location(file: file, byteOffset: 0)
                    ),
                ]
            }
        }

        #expect(!violations(Example(code: "_ = 0"), config: Spec.configuration!).isEmpty)
    }

    @Test
    func collectsAllFiles() {
        struct Spec: MockCollectingRule {
            var configuration = SeverityConfiguration<Self>(.warning)

            func collectInfo(for file: SwiftLintFile) -> String {
                file.contents
            }

            func validate(file: SwiftLintFile, collectedInfo: [SwiftLintFile: String]) -> [StyleViolation] {
                let values = collectedInfo.values
                #expect(values.contains("foo"))
                #expect(values.contains("bar"))
                #expect(values.contains("baz"))
                return [
                    StyleViolation(
                        ruleDescription: Self.description,
                        location: Location(file: file, byteOffset: 0)
                    ),
                ]
            }
        }

        let inputs = ["foo", "bar", "baz"]
        #expect(inputs.violations(config: Spec.configuration!).count == inputs.count)
    }

    @Test
    func collectsAnalyzerFiles() {
        struct Spec: MockCollectingRule, AnalyzerRule {
            var configuration = SeverityConfiguration<Self>(.warning)

            func collectInfo(for _: SwiftLintFile, compilerArguments: [String]) -> [String] {
                compilerArguments
            }

            func validate(
                file: SwiftLintFile,
                collectedInfo: [SwiftLintFile: [String]],
                compilerArguments: [String]
            ) -> [StyleViolation] {
                #expect(collectedInfo[file] == compilerArguments)
                return [
                    StyleViolation(
                        ruleDescription: Self.description,
                        location: Location(file: file, byteOffset: 0)
                    ),
                ]
            }
        }

        #expect(violations(Example(code: "_ = 0"), config: Spec.configuration!, requiresFileOnDisk: true).isNotEmpty)
    }

    @Test
    func analyzerRuleCollectionIsSerialized() {
        let probe = SchedulingProbe()
        let rules: [any Rule] = [
            AnalyzerSchedulingRule<FirstSchedulingRule>(collectionProbe: probe),
            AnalyzerSchedulingRule<SecondSchedulingRule>(collectionProbe: probe),
        ]
        let linter = Linter(
            file: SwiftLintFile(contents: "let value = 1"),
            configuration: schedulingConfiguration(rules),
            compilerArguments: ["-module-name", "SchedulingTest"]
        )

        _ = linter.collect(into: RuleStorage())

        #expect(!probe.didOverlap)
    }

    @Test
    func analyzerRuleValidationIsSerialized() {
        let probe = SchedulingProbe()
        let rules: [any Rule] = [
            AnalyzerSchedulingRule<FirstSchedulingRule>(validationProbe: probe),
            AnalyzerSchedulingRule<SecondSchedulingRule>(validationProbe: probe),
        ]
        let storage = RuleStorage()
        let linter = Linter(
            file: SwiftLintFile(contents: "let value = 1"),
            configuration: schedulingConfiguration(rules),
            compilerArguments: ["-module-name", "SchedulingTest"]
        )

        let collectedLinter = linter.collect(into: storage)
        _ = collectedLinter.styleViolations(using: storage)

        #expect(!probe.didOverlap)
    }

    @Test
    func lintRuleCollectionRemainsParallel() {
        let probe = SchedulingProbe()
        let rules: [any Rule] = [
            LintSchedulingRule<FirstSchedulingRule>(collectionProbe: probe),
            LintSchedulingRule<SecondSchedulingRule>(collectionProbe: probe),
        ]
        let linter = Linter(
            file: SwiftLintFile(contents: "let value = 1"),
            configuration: schedulingConfiguration(rules)
        )

        _ = linter.collect(into: RuleStorage())

        #expect(probe.didOverlap)
    }

    @Test
    func lintRuleValidationRemainsParallel() {
        let probe = SchedulingProbe()
        let rules: [any Rule] = [
            LintSchedulingRule<FirstSchedulingRule>(validationProbe: probe),
            LintSchedulingRule<SecondSchedulingRule>(validationProbe: probe),
        ]
        let storage = RuleStorage()
        let linter = Linter(
            file: SwiftLintFile(contents: "let value = 1"),
            configuration: schedulingConfiguration(rules)
        )

        let collectedLinter = linter.collect(into: storage)
        _ = collectedLinter.styleViolations(using: storage)

        #expect(probe.didOverlap)
    }

    @Test
    func corrects() {
        struct Spec: MockCollectingRule, CorrectableRule {
            var configuration = SeverityConfiguration<Self>(.warning)

            func collectInfo(for file: SwiftLintFile) -> String {
                file.contents
            }

            func validate(file: SwiftLintFile, collectedInfo: [SwiftLintFile: String]) -> [StyleViolation] {
                if collectedInfo[file] == "baz" {
                    return [
                        StyleViolation(
                            ruleDescription: Self.description,
                            location: Location(file: file, byteOffset: 2)
                        ),
                    ]
                }
                return []
            }

            func correct(file: SwiftLintFile, collectedInfo: [SwiftLintFile: String]) -> Int {
                collectedInfo[file] == "baz" ? 1 : 0
            }

            func correct(file: SwiftLintFile) -> Int {
                correct(file: file, collectedInfo: [file: collectInfo(for: file)])
            }
        }

        struct AnalyzerSpec: MockCollectingRule, AnalyzerRule, CorrectableRule {
            var configuration = SeverityConfiguration<Self>(.warning)

            func collectInfo(for file: SwiftLintFile) -> String {
                file.contents
            }

            func validate(
                file: SwiftLintFile,
                collectedInfo: [SwiftLintFile: String],
                compilerArguments _: [String]
            ) -> [StyleViolation] {
                collectedInfo[file] == "baz"
                    ? [
                        .init(
                            ruleDescription: Spec.description,
                            location: Location(file: file, byteOffset: 2)
                        ),
                    ]
                    : []
            }

            func correct(
                file: SwiftLintFile,
                collectedInfo: [SwiftLintFile: String],
                compilerArguments _: [String]
            ) -> Int {
                collectedInfo[file] == "baz" ? 1 : 0
            }

            func correct(file: SwiftLintFile) -> Int {
                correct(file: file, collectedInfo: [file: collectInfo(for: file)], compilerArguments: [])
            }
        }

        let inputs = ["foo", "baz"]
        #expect(inputs.corrections(config: Spec.configuration!).count == 1)
        #expect(inputs.corrections(config: AnalyzerSpec.configuration!, requiresFileOnDisk: true).count == 1)
    }
}

private func schedulingConfiguration(_ rules: [any Rule]) -> Configuration {
    Configuration(
        rulesMode: .onlyConfiguration(Set(rules.map { type(of: $0).identifier })),
        allRulesWrapped: rules.map { ($0, false) },
        ruleList: RuleList(rules: rules.map { type(of: $0) })
    )
}

private protocol SchedulingRuleMarker: Sendable {
    static var identifier: String { get }
}

private enum FirstSchedulingRule: SchedulingRuleMarker {
    static let identifier = "first_scheduling_rule"
}

private enum SecondSchedulingRule: SchedulingRuleMarker {
    static let identifier = "second_scheduling_rule"
}

private struct AnalyzerSchedulingRule<Marker: SchedulingRuleMarker>:
    MockCollectingRule, AnalyzerRule, SourceKitFreeRule {
    var configuration = SeverityConfiguration<Self>(.warning)
    private let collectionProbe: SchedulingProbe?
    private let validationProbe: SchedulingProbe?

    init() {
        collectionProbe = nil
        validationProbe = nil
    }

    init(collectionProbe: SchedulingProbe? = nil, validationProbe: SchedulingProbe? = nil) {
        self.collectionProbe = collectionProbe
        self.validationProbe = validationProbe
    }

    static var description: RuleDescription {
        RuleDescription(identifier: Marker.identifier, name: "", description: "", kind: .lint)
    }

    func collectInfo(for _: SwiftLintFile, compilerArguments _: [String]) -> Bool {
        collectionProbe?.recordInvocation()
        return true
    }

    func validate(
        file _: SwiftLintFile,
        collectedInfo _: [SwiftLintFile: Bool],
        compilerArguments _: [String]
    ) -> [StyleViolation] {
        validationProbe?.recordInvocation()
        return []
    }
}

private struct LintSchedulingRule<Marker: SchedulingRuleMarker>: MockCollectingRule, SourceKitFreeRule {
    var configuration = SeverityConfiguration<Self>(.warning)
    private let collectionProbe: SchedulingProbe?
    private let validationProbe: SchedulingProbe?

    init() {
        collectionProbe = nil
        validationProbe = nil
    }

    init(collectionProbe: SchedulingProbe? = nil, validationProbe: SchedulingProbe? = nil) {
        self.collectionProbe = collectionProbe
        self.validationProbe = validationProbe
    }

    static var description: RuleDescription {
        RuleDescription(identifier: Marker.identifier, name: "", description: "", kind: .lint)
    }

    func collectInfo(for _: SwiftLintFile) -> Bool {
        collectionProbe?.recordInvocation()
        return true
    }

    func validate(file _: SwiftLintFile, collectedInfo _: [SwiftLintFile: Bool]) -> [StyleViolation] {
        validationProbe?.recordInvocation()
        return []
    }
}

// All mutable state is private, protected by `lock`, and no mutable reference escapes.
private final class SchedulingProbe: @unchecked Sendable {
    private let lock = NSLock()
    private let overlapSignal = DispatchSemaphore(value: 0)
    private var activeInvocations = 0
    private var invocationCount = 0
    private var overlapDetected = false

    var didOverlap: Bool {
        lock.withLock { overlapDetected }
    }

    func recordInvocation() {
        let invocation = lock.withLock { () -> Int in
            invocationCount += 1
            activeInvocations += 1
            if activeInvocations > 1 {
                overlapDetected = true
                overlapSignal.signal()
            }
            return invocationCount
        }

        if invocation == 1 {
            _ = overlapSignal.wait(timeout: .now() + .seconds(1))
        }

        lock.withLock {
            activeInvocations -= 1
        }
    }
}

private protocol MockCollectingRule: CollectingRule {}
extension MockCollectingRule {
    @RuleConfigurationDescriptionBuilder
    var configurationDescription: some Documentable { RuleConfigurationOption.noOptions }
    static var description: RuleDescription {
        RuleDescription(identifier: "mock_test_rule_for_swiftlint_tests", name: "", description: "", kind: .lint)
    }
    static var configuration: Configuration? {
        Configuration(rulesMode: .onlyConfiguration([identifier]), ruleList: RuleList(rules: self))
    }

    init(configuration _: Any) { self.init() }
}
