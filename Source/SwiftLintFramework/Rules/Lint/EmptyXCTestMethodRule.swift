import SourceKittenFramework

public struct EmptyXCTestMethodRule: Rule, OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "empty_xctest_method",
        name: "Empty XCTest Method",
        description: "Empty XCTest method should be avoided.",
        kind: .lint,
        nonTriggeringExamples: EmptyXCTestMethodRuleExamples.nonTriggeringExamples,
        triggeringExamples: EmptyXCTestMethodRuleExamples.triggeringExamples
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
                let kind = subDictionary.declarationKind,
                let name = subDictionary.name,
                XCTestHelpers.isXCTestMember(kind: kind, name: name,
                                             attributes: subDictionary.enclosedSwiftAttributes),
                let offset = subDictionary.offset,
                subDictionary.enclosedVarParameters.isEmpty,
                subDictionary.substructure.isEmpty else { return nil }

            return StyleViolation(ruleDescription: Self.description,
                                  severity: configuration.severity,
                                  location: Location(file: file, byteOffset: offset))
        }
    }
}
