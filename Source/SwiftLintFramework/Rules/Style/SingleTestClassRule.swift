import SourceKittenFramework

public struct SingleTestClassRule: Rule, OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public static let description = RuleDescription(
        identifier: "single_test_class",
        name: "Single Test Class",
        description: "Test files should contain a single QuickSpec or XCTestCase class.",
        kind: .style,
        nonTriggeringExamples: [
            "class FooTests {  }\n",
            "class FooTests: QuickSpec {  }\n",
            "class FooTests: XCTestCase {  }\n"
        ],
        triggeringExamples: [
            "↓class FooTests: QuickSpec {  }\n↓class BarTests: QuickSpec {  }\n",
            "↓class FooTests: QuickSpec {  }\n↓class BarTests: QuickSpec {  }\n↓class TotoTests: QuickSpec {  }\n",
            "↓class FooTests: XCTestCase {  }\n↓class BarTests: XCTestCase {  }\n",
            "↓class FooTests: XCTestCase {  }\n↓class BarTests: XCTestCase {  }\n↓class TotoTests: XCTestCase {  }\n",
            "↓class FooTests: QuickSpec {  }\n↓class BarTests: XCTestCase {  }\n",
            "↓class FooTests: QuickSpec {  }\n↓class BarTests: XCTestCase {  }\nclass TotoTests {  }\n"
        ]
    )

    private let testClasses: Set = ["QuickSpec", "XCTestCase"]

    public init() {}

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let classes = testClasses(in: file)

        guard classes.count > 1 else { return [] }

        return classes.compactMap { dictionary in
            guard let offset = dictionary.offset else { return nil }

            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: configuration.severity,
                                  location: Location(file: file, byteOffset: offset),
                                  reason: "\(classes.count) test classes found in this file.")
        }
    }

    private func testClasses(in file: SwiftLintFile) -> [SourceKittenDictionary] {
        let dict = file.structureDictionary
        return dict.substructure.filter { dictionary in
            guard dictionary.declarationKind == .class else { return false }
            return !testClasses.isDisjoint(with: dictionary.inheritedTypes)
        }
    }
}
