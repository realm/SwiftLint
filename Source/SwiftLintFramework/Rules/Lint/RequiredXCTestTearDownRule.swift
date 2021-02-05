import SourceKittenFramework

public struct RequiredXCTestTearDownRule: Rule, OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public static let description = RuleDescription(
        identifier: "required_xctest_teardown",
        name: "Required XCTest Tear Down",
        description: "Test classes must implement tearDown when setUp is provided.",
        kind: .lint,
        nonTriggeringExamples: [
            Example(#"""
            final class FooTests: XCTestCase {
                override func setUp() {}
                override func tearDown() {}
            }
            """#),
            Example(#"""
            final class FooTests: XCTestCase {
                override func setUpWithError() throws {}
                override func tearDown() {}
            }
            """#),
            Example(#"""
            final class FooTests: XCTestCase {
                override func setUp() {}
                override func tearDownWithError() throws {}
            }
            """#),
            Example(#"""
            final class FooTests: XCTestCase {
                override func setUpWithError() throws {}
                override func tearDownWithError() throws {}
            }
            final class BarTests: XCTestCase {
                override func setUpWithError() throws {}
                override func tearDownWithError() throws {}
            }
            """#),
            Example(#"""
            struct FooTests {
                override func setUp() {}
            }
            class BarTests {
                override func setUpWithError() throws {}
            }
            """#),
            Example(#"""
            final class FooTests: XCTestCase {
                override func setUpAlLExamples() {}
            }
            """#),
            Example(#"""
            final class FooTests: XCTestCase {
                class func setUp() {}
                class func tearDown() {}
            }
            """#)
        ],
        triggeringExamples: [
            Example(#"""
            final class ↓FooTests: XCTestCase {
                override func setUp() {}
            }
            """#),
            Example(#"""
            final class ↓FooTests: XCTestCase {
                override func setUpWithError() throws {}
            }
            """#),
            Example(#"""
            final class FooTests: XCTestCase {
                override func setUp() {}
                override func tearDownWithError() throws {}
            }
            final class ↓BarTests: XCTestCase {
                override func setUpWithError() throws {}
            }
            """#),
            Example(#"""
            final class ↓FooTests: XCTestCase {
                class func setUp() {}
            }
            """#)
        ]
    )

    public init() {}

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        testClasses(in: file).compactMap { violations(in: file, for: $0) }
    }

    private func testClasses(in file: SwiftLintFile) -> [SourceKittenDictionary] {
        file.structureDictionary.substructure.filter { dictionary in
            guard dictionary.declarationKind == .class else { return false }
            return dictionary.inheritedTypes.contains("XCTestCase")
        }
    }

    private func violations(in file: SwiftLintFile,
                            for dictionary: SourceKittenDictionary) -> StyleViolation? {
        let methods = dictionary.substructure
            .compactMap { XCTMethod($0.name) }

        guard
            methods.contains(.setUp) == true,
            methods.contains(.tearDown) == false,
            let offset = dictionary.nameOffset
        else {
            return nil
        }

        return StyleViolation(ruleDescription: Self.description,
                              severity: configuration.severity,
                              location: Location(file: file, byteOffset: offset))
    }
}

// MARK: - Private

private enum XCTMethod {
    case setUp
    case tearDown

    init?(_ name: String?) {
        switch name {
        case "setUp()", "setUpWithError()": self = .setUp
        case "tearDown()", "tearDownWithError()": self = .tearDown
        default: return nil
        }
    }
}
