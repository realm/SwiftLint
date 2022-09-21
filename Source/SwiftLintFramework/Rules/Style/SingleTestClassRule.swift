import SourceKittenFramework

public struct SingleTestClassRule: Rule, OptInRule, ConfigurationProviderRule {
    public var configuration = SingleTestClassConfiguration()

    public static let description = RuleDescription(
        identifier: "single_test_class",
        name: "Single Test Class",
        description: "Test files should contain a single QuickSpec or XCTestCase class.",
        kind: .style,
        nonTriggeringExamples: [
            Example("class FooTests {  }\n"),
            Example("class FooTests: QuickSpec {  }\n"),
            Example("class FooTests: XCTestCase {  }\n")
        ],
        triggeringExamples: [
            Example("""
            ↓class FooTests: QuickSpec {  }
            ↓class BarTests: QuickSpec {  }
            """),
            Example("""
            ↓class FooTests: QuickSpec {  }
            ↓class BarTests: QuickSpec {  }
            ↓class TotoTests: QuickSpec {  }
            """),
            Example("""
            ↓class FooTests: XCTestCase {  }
            ↓class BarTests: XCTestCase {  }
            """),
            Example("""
            ↓class FooTests: XCTestCase {  }
            ↓class BarTests: XCTestCase {  }
            ↓class TotoTests: XCTestCase {  }
            """),
            Example("""
            ↓class FooTests: QuickSpec {  }
            ↓class BarTests: XCTestCase {  }
            """),
            Example("""
            ↓class FooTests: QuickSpec {  }
            ↓class BarTests: XCTestCase {  }
            class TotoTests {  }
            """)
        ]
    )

    public init() {}

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let classes = testClasses(in: file)

        guard classes.count > 1 else { return [] }

        return classes.compactMap { dictionary in
            guard let offset = dictionary.offset else { return nil }

            return StyleViolation(ruleDescription: Self.description,
                                  severity: configuration.severity,
                                  location: Location(file: file, byteOffset: offset),
                                  reason: "\(classes.count) test classes found in this file.")
        }
    }

    private func testClasses(in file: SwiftLintFile) -> [SourceKittenDictionary] {
        return file.structureDictionary.substructure.filter { dictionary in
            dictionary.declarationKind == .class &&
            configuration.testParentClasses.intersection(dictionary.inheritedTypes).isNotEmpty
        }
    }
}
