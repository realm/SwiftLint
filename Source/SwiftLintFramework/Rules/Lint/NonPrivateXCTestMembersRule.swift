import SourceKittenFramework

public struct NonPrivateXCTestMembersRule: Rule, OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "non_private_xctest_member",
        name: "Non-private XCTest member",
        description: "All non-test XCTest members should be private.",
        kind: .lint,
        nonTriggeringExamples: NonPrivateXCTestMembersRuleExamples.nonTriggeringExamples,
        triggeringExamples: NonPrivateXCTestMembersRuleExamples.triggeringExamples
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        return testClasses(in: file).flatMap { violations(in: file, for: $0) }
    }

    // MARK: - Private

    private func testClasses(in file: SwiftLintFile) -> [SourceKittenDictionary] {
        let dict = file.structureDictionary
        return dict.substructure.filter { dictionary in
            guard dictionary.declarationKind == .class else { return false }
            return dictionary.inheritedTypes.contains("XCTestCase")
        }
    }

    private func violations(in file: SwiftLintFile,
                            for dictionary: SourceKittenDictionary) -> [StyleViolation] {
        return dictionary.substructure.compactMap { subDictionary -> StyleViolation? in
            guard
                let name = subDictionary.name, !isXCTestMethod(name),
                let acl = subDictionary.accessibility, acl != .fileprivate && acl != .private,
                let offset = subDictionary.offset else { return nil }

            return StyleViolation(ruleDescription: Self.description,
                                  severity: configuration.severity,
                                  location: Location(file: file, byteOffset: offset))
        }
    }

    private func isXCTestMethod(_ method: String) -> Bool {
        return method.hasPrefix("test") || method == "setUp()" || method == "tearDown()"
    }
}
