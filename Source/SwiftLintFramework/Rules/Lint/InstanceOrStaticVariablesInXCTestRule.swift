import SourceKittenFramework

public struct InstanceOrStaticVariablesInXCTestRule: Rule, OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
    // MARK: - Properties

    public var configuration = SeverityConfiguration(.warning)

    public static let description = RuleDescription(
        identifier: "instance_or_static_variable_xctest",
        name: "Instance or Static Variables in XCTest Subclass",
        description: "Test classes must not contain instance or static variables.",
        kind: .lint,
        nonTriggeringExamples: [
            Example(#"""
            final class FooTests: XCTestCase {
                override func setUp() {}
                func testExample() {}
            }
            """#)
        ],
        triggeringExamples: [
            Example(#"""
            final class ↓FooTests: XCTestCase {
                let instanceVariable = 2
            }
            """#),
            Example(#"""
            final class ↓FooTests: XCTestCase {
                private let instanceVariable = 2
            }
            """#),
            Example(#"""
            final class ↓FooTests: XCTestCase {
                var instanceVariable = 5
            }
            """#),
            Example(#"""
            final class ↓FooTests: XCTestCase {
                static let staticVariable = 5
            }
            """#),
            Example(#"""
            final class ↓FooTests: XCTestCase {
                static var staticVariable = 5
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
        let vars = dictionary.substructure
            .compactMap { $0.kind == "source.lang.swift.decl.var.instance" ||
                          $0.kind == "source.lang.swift.decl.var.static"
            }
            .filter { $0 }

        guard
            !vars.isEmpty,
            let offset = dictionary.nameOffset
        else {
            return nil
        }

        return StyleViolation(ruleDescription: Self.description,
                              severity: configuration.severity,
                              location: Location(file: file, byteOffset: offset))
    }
}
