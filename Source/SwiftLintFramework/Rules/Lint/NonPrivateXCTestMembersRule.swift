import Foundation
import SourceKittenFramework

public struct NonPrivateXCTestMembersRule: Rule, OptInRule, ConfigurationProviderRule, AutomaticTestableRule,
                                           SubstitutionCorrectableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "non_private_xctest_member",
        name: "Non-private XCTest member",
        description: "All non-test XCTest members should be private.",
        kind: .lint,
        nonTriggeringExamples: NonPrivateXCTestMembersRuleExamples.nonTriggeringExamples,
        triggeringExamples: NonPrivateXCTestMembersRuleExamples.triggeringExamples,
        corrections: NonPrivateXCTestMembersRuleExamples.corrections
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        return violationRanges(in: file).map { range in
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: range.location))
        }
    }

    // MARK: - SubstitutionCorrectableRule

    public func violationRanges(in file: SwiftLintFile) -> [NSRange] {
        return testClasses(in: file).flatMap { violationRanges(in: file, for: $0) }
    }

    public func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String)? {
        return (violationRange, "private ")
    }

    // MARK: - Private

    private func testClasses(in file: SwiftLintFile) -> [SourceKittenDictionary] {
        let dict = file.structureDictionary
        return dict.substructure.filter { dictionary in
            guard dictionary.declarationKind == .class else { return false }
            return dictionary.inheritedTypes.contains("XCTestCase")
        }
    }

    private func violationRanges(in file: SwiftLintFile,
                                 for dictionary: SourceKittenDictionary) -> [NSRange] {
        return dictionary.substructure.compactMap { subDictionary in
            guard
                let name = subDictionary.name, !isXCTestMethod(name),
                let acl = subDictionary.accessibility, acl != .fileprivate && acl != .private,
                let offset = subDictionary.offset else { return nil }
            return file.stringView.byteRangeToNSRange(ByteRange(location: offset, length: 0))
        }
    }

    private func isXCTestMethod(_ method: String) -> Bool {
        let lifecycleMethods = [
            "setUp()",
            "setUpWithError()",
            "tearDown()",
            "tearDownWithError()"
        ]

        return method.hasPrefix("test") || lifecycleMethods.contains(method)
    }
}
