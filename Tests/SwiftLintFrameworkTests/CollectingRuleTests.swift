@_spi(TestHelper)
@testable import SwiftLintFramework
@_spi(TestHelper)
import SwiftLintTestHelpers
import XCTest

class CollectingRuleTests: XCTestCase {
    func testCollectsIntoStorage() async throws {
        struct Spec: MockCollectingRule {
            func collectInfo(for file: SwiftLintFile) -> Int {
                return 42
            }
            func validate(file: SwiftLintFile, collectedInfo: [SwiftLintFile: Int]) -> [StyleViolation] {
                XCTAssertEqual(collectedInfo[file], 42)
                return [StyleViolation(ruleDescription: Self.description,
                                       location: Location(file: file, byteOffset: 0))]
            }
        }

        let violations = try await violations(Example("_ = 0"), config: Spec.configuration!)
        XCTAssertNotEqual(violations, [])
    }

    func testCollectsAllFiles() async throws {
        struct Spec: MockCollectingRule {
            func collectInfo(for file: SwiftLintFile) -> String {
                return file.contents
            }
            func validate(file: SwiftLintFile, collectedInfo: [SwiftLintFile: String]) -> [StyleViolation] {
                let values = collectedInfo.values
                XCTAssertTrue(values.contains("foo"))
                XCTAssertTrue(values.contains("bar"))
                XCTAssertTrue(values.contains("baz"))
                return [StyleViolation(ruleDescription: Self.description,
                                       location: Location(file: file, byteOffset: 0))]
            }
        }

        let inputs = ["foo", "bar", "baz"]
        let violations = try await inputs.violations(config: Spec.configuration!)
        XCTAssertEqual(violations.count, inputs.count)
    }

    func testCollectsAnalyzerFiles() async throws {
        struct Spec: MockCollectingRule, AnalyzerRule {
            func collectInfo(for file: SwiftLintFile, compilerArguments: [String]) -> [String] {
                return compilerArguments
            }
            func validate(file: SwiftLintFile, collectedInfo: [SwiftLintFile: [String]], compilerArguments: [String])
                -> [StyleViolation] {
                    XCTAssertEqual(collectedInfo[file], compilerArguments)
                    return [StyleViolation(ruleDescription: Self.description,
                                           location: Location(file: file, byteOffset: 0))]
            }
        }

        let violations = try await violations(Example("_ = 0"), config: Spec.configuration!, requiresFileOnDisk: true)
        XCTAssertNotEqual(violations, [])
    }

    func testCorrects() {
        struct Spec: MockCollectingRule, CollectingCorrectableRule {
            func collectInfo(for file: SwiftLintFile) -> String {
                return file.contents
            }

            func validate(file: SwiftLintFile, collectedInfo: [SwiftLintFile: String]) -> [StyleViolation] {
                if collectedInfo[file] == "baz" {
                    return [StyleViolation(ruleDescription: Self.description,
                                           location: Location(file: file, byteOffset: 2))]
                } else {
                    return []
                }
            }

            func correct(file: SwiftLintFile, collectedInfo: [SwiftLintFile: String]) -> [Correction] {
                if collectedInfo[file] == "baz" {
                    return [Correction(ruleDescription: Self.description,
                                       location: Location(file: file, byteOffset: 2))]
                } else {
                    return []
                }
            }
        }

        struct AnalyzerSpec: MockCollectingRule, AnalyzerRule, CollectingCorrectableRule {
            func collectInfo(for file: SwiftLintFile, compilerArguments: [String]) -> String {
                return file.contents
            }

            func validate(file: SwiftLintFile, collectedInfo: [SwiftLintFile: String], compilerArguments: [String])
                -> [StyleViolation] {
                    if collectedInfo[file] == "baz" {
                        return [StyleViolation(ruleDescription: Spec.description,
                                               location: Location(file: file, byteOffset: 2))]
                    } else {
                        return []
                    }
            }

            func correct(file: SwiftLintFile, collectedInfo: [SwiftLintFile: String],
                         compilerArguments: [String]) -> [Correction] {
                if collectedInfo[file] == "baz" {
                    return [Correction(ruleDescription: Spec.description,
                                       location: Location(file: file, byteOffset: 2))]
                } else {
                    return []
                }
            }
        }

        let inputs = ["foo", "baz"]
        XCTAssertEqual(inputs.corrections(config: Spec.configuration!).count, 1)
        XCTAssertEqual(inputs.corrections(config: AnalyzerSpec.configuration!, requiresFileOnDisk: true).count, 1)
    }
}

private protocol MockCollectingRule: CollectingRule {}
extension MockCollectingRule {
    var configurationDescription: String { return "N/A" }
    static var description: RuleDescription {
        return RuleDescription(identifier: "test_rule", name: "", description: "", kind: .lint)
    }
    static var configuration: Configuration? {
        return Configuration(rulesMode: .only([description.identifier]), ruleList: RuleList(rules: self))
    }

    init(configuration: Any) throws { self.init() }
}
