import Foundation
import SourceKittenFramework

public struct TestCaseAccessibilityRule: Rule, OptInRule, ConfigurationProviderRule,
                                         SubstitutionCorrectableRule {
    public var configuration = TestCaseAccessibilityConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "test_case_accessibility",
        name: "Test case accessibility",
        description: "Test cases should only contain private non-test members.",
        kind: .lint,
        nonTriggeringExamples: TestCaseAccessibilityRuleExamples.nonTriggeringExamples,
        triggeringExamples: TestCaseAccessibilityRuleExamples.triggeringExamples,
        corrections: TestCaseAccessibilityRuleExamples.corrections
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        return testClasses(in: file).flatMap { dictionary in
            violationRanges(in: file, for: dictionary).map { range in
                return StyleViolation(ruleDescription: Self.description,
                                      severity: configuration.severity,
                                      location: Location(file: file, characterOffset: range.location))
            }
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
        return file.structureDictionary.substructure.filter { dictionary in
            dictionary.declarationKind == .class && dictionary.inheritedTypes.contains("XCTestCase")
        }
    }

    private func violationRanges(in file: SwiftLintFile,
                                 for dictionary: SourceKittenDictionary) -> [NSRange] {
        return dictionary.substructure.compactMap { subDictionary -> NSRange? in
            guard
                let kind = subDictionary.declarationKind,
                kind != .varLocal,
                let name = subDictionary.name,
                !isXCTestMember(kind: kind, name: name, dictionary: subDictionary),
                let offset = subDictionary.offset,
                subDictionary.accessibility?.isPrivate != true else { return nil }

            return file.stringView.byteRangeToNSRange(ByteRange(location: offset, length: 0))
        }
    }

    private func isXCTestMember(kind: SwiftDeclarationKind, name: String,
                                dictionary: SourceKittenDictionary) -> Bool {
        return XCTestHelpers.isXCTestMember(kind: kind, name: name, dictionary: dictionary)
            || configuration.allowedPrefixes.contains(where: name.hasPrefix)
    }
}
