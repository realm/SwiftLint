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

    public func validate(file: File) -> [StyleViolation] {
        return testClasses(in: file).flatMap { violations(in: file, for: $0) }
    }

    // MARK: - Private

    private func testClasses(in file: File) -> [[String: SourceKitRepresentable]] {
        return file.structure.dictionary.substructure.filter { dictionary in
            guard
                let kind = dictionary.kind,
                SwiftDeclarationKind(rawValue: kind) == .class else { return false }
            return dictionary.inheritedTypes.contains("XCTestCase")
        }
    }

    private func violations(in file: File,
                            for dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        return dictionary.substructure.compactMap { subDictionary -> StyleViolation? in
            guard
                let kind = subDictionary.kind.flatMap(SwiftDeclarationKind.init),
                SwiftDeclarationKind.functionKinds.contains(kind),
                let name = subDictionary.name, isXCTestMethod(name),
                let offset = subDictionary.offset,
                subDictionary.enclosedVarParameters.isEmpty,
                subDictionary.substructure.isEmpty else { return nil }

            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: configuration.severity,
                                  location: Location(file: file, byteOffset: offset))
        }
    }

    private func isXCTestMethod(_ method: String) -> Bool {
        return method.hasPrefix("test") || method == "setUp()" || method == "tearDown()"
    }
}
