import SourceKittenFramework
@testable import SwiftLintFramework
import XCTest

// swiftlint:disable nesting

class CollectingRuleTests: XCTestCase {
    func testCollectsIntoStorage() {
        struct Spec: MockCollectingRule {
            func collect(infoFor file: File) -> Int {
                return 42
            }
            func validate(file: File, collectedInfo: [File: Int]) -> [StyleViolation] {
                XCTAssertEqual(collectedInfo[file], 42)
                return [StyleViolation(ruleDescription: Spec.description,
                                       location: Location(file: file, byteOffset: 0))]
            }
        }

        XCTAssertFalse(violations("", config: Spec.configuration!).isEmpty)
    }

    func testCollectsAllFiles() {
        struct Spec: MockCollectingRule {
            func collect(infoFor file: File) -> String {
                return file.contents
            }
            func validate(file: File, collectedInfo: [File: String]) -> [StyleViolation] {
                let values = collectedInfo.values
                XCTAssertTrue(values.contains("foo"))
                XCTAssertTrue(values.contains("bar"))
                XCTAssertTrue(values.contains("baz"))
                return [StyleViolation(ruleDescription: Spec.description,
                                       location: Location(file: file, byteOffset: 0))]
            }
        }

        let inputs = ["foo", "bar", "baz"]
        XCTAssertEqual(inputs.violations(config: Spec.configuration!).count, inputs.count)
    }

    func testCollectsAnalyzerFiles() {
        struct Spec: MockCollectingRule & AnalyzerRule {
            func collect(infoFor file: File, compilerArguments: [String]) -> [String] {
                return compilerArguments
            }
            func validate(file: File, collectedInfo: [File: [String]], compilerArguments: [String])
                -> [StyleViolation] {
                    XCTAssertEqual(collectedInfo[file], compilerArguments)
                    return [StyleViolation(ruleDescription: Spec.description,
                                           location: Location(file: file, byteOffset: 0))]
            }
        }

        XCTAssertFalse(violations("", config: Spec.configuration!, requiresFileOnDisk: true).isEmpty)
    }
}

private protocol MockCollectingRule: CollectingRule {}
extension MockCollectingRule {
    var configurationDescription: String { return "N/A" }
    static var description: RuleDescription {
        return RuleDescription(identifier: "test_rule", name: "", description: "", kind: .lint)
    }
    static var configuration: Configuration? {
        return Configuration(rulesMode: .whitelisted([description.identifier]), ruleList: RuleList(rules: self))
    }

    init(configuration: Any) throws { self.init() }
}
