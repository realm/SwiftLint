import SourceKittenFramework

public struct TestCaseAccessibilityRule: Rule, OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = TestCaseAccessibilityConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "test_case_accessibility",
        name: "Test case accessibility",
        description: "Test cases should only contain private non-test members.",
        kind: .lint,
        nonTriggeringExamples: TestCaseAccessibilityRuleExamples.nonTriggeringExamples,
        triggeringExamples: TestCaseAccessibilityRuleExamples.triggeringExamples
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        return testClasses(in: file).flatMap { violations(in: file, for: $0) }
    }

    // MARK: - Private

    private func testClasses(in file: SwiftLintFile) -> [SourceKittenDictionary] {
        let dict = file.structureDictionary
        return dict.substructure.filter { dictionary in
            dictionary.declarationKind == .class && dictionary.inheritedTypes.contains("XCTestCase")
        }
    }

    private func violations(in file: SwiftLintFile,
                            for dictionary: SourceKittenDictionary) -> [StyleViolation] {
        return dictionary.substructure.compactMap { subDictionary -> StyleViolation? in
            guard
                let kind = subDictionary.declarationKind,
                kind != .varLocal,
                let name = subDictionary.name,
                !isXCTestMember(kind: kind, name: name, attributes: subDictionary.enclosedSwiftAttributes),
                let offset = subDictionary.offset,
                subDictionary.accessibility?.isPrivate != true else { return nil }

            return StyleViolation(ruleDescription: Self.description,
                                  severity: configuration.severity,
                                  location: Location(file: file, byteOffset: offset))
        }
    }

    private func isXCTestMember(kind: SwiftDeclarationKind, name: String,
                                attributes: [SwiftDeclarationAttributeKind]) -> Bool {
        return XCTestHelpers.isXCTestMember(kind: kind, name: name, attributes: attributes)
            || configuration.allowedPrefixes.contains(where: name.hasPrefix)
    }
}
