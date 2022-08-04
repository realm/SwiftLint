import SourceKittenFramework

public struct BalancedXCTestLifecycleRule: Rule, OptInRule, ConfigurationProviderRule {
    // MARK: - Properties

    public var configuration = SeverityConfiguration(.warning)

    public static let description = RuleDescription(
        identifier: "balanced_xctest_lifecycle",
        name: "Balanced XCTest life-cycle",
        description: "Test classes must implement balanced setUp and tearDown methods.",
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
                class func tearDown() {}
            }
            """#),
            Example(#"""
            final class ↓FooTests: XCTestCase {
                override func tearDown() {}
            }
            """#),
            Example(#"""
            final class ↓FooTests: XCTestCase {
                override func tearDownWithError() throws {}
            }
            """#),
            Example(#"""
            final class FooTests: XCTestCase {
                override func setUp() {}
                override func tearDownWithError() throws {}
            }
            final class ↓BarTests: XCTestCase {
                override func tearDownWithError() throws {}
            }
            """#)
        ]
    )

    // MARK: - Life cycle

    public init() {}

    // MARK: - Public

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        testClasses(in: file).compactMap { violations(in: file, for: $0) }
    }

    // MARK: - Private

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
            methods.contains(.setUp) != methods.contains(.tearDown),
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
