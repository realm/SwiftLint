import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

private let fixturesDirectory = "\(TestResources.path())/FileNameRuleFixtures"

@Suite(.rulesRegistered)
struct FileNameRuleTests {
    private func validate(fileName: String,
                          excluded: [String]? = nil,
                          excludedPaths: [String]? = nil,
                          prefixPattern: String? = nil,
                          suffixPattern: String? = nil,
                          nestedTypeSeparator: String? = nil,
                          requireFullyQualifiedNames: Bool = false) throws -> [StyleViolation] {
        let file = SwiftLintFile(path: fixturesDirectory.stringByAppendingPathComponent(fileName))!

        var configuration = [String: Any]()

        if let excluded {
            configuration["excluded"] = excluded
        }
        if let excludedPaths {
            configuration["excluded_paths"] = excludedPaths
        }
        if let prefixPattern {
            configuration["prefix_pattern"] = prefixPattern
        }
        if let suffixPattern {
            configuration["suffix_pattern"] = suffixPattern
        }
        if let nestedTypeSeparator {
            configuration["nested_type_separator"] = nestedTypeSeparator
        }
        if requireFullyQualifiedNames {
            configuration["require_fully_qualified_names"] = requireFullyQualifiedNames
        }

        let rule = try FileNameRule(configuration: configuration)

        return rule.validate(file: file)
    }

    @Test
    func mainDoesntTrigger() throws {
        try #expect(validate(fileName: "main.swift").isEmpty)
    }

    @Test
    func linuxMainDoesntTrigger() throws {
        try #expect(validate(fileName: "LinuxMain.swift").isEmpty)
    }

    @Test
    func classNameDoesntTrigger() throws {
        try #expect(validate(fileName: "MyClass.swift").isEmpty)
    }

    @Test
    func structNameDoesntTrigger() throws {
        try #expect(validate(fileName: "MyStruct.swift").isEmpty)
    }

    @Test
    func macroNameDoesntTrigger() throws {
        try #expect(validate(fileName: "MyMacro.swift").isEmpty)
    }

    @Test
    func extensionNameDoesntTrigger() throws {
        try #expect(validate(fileName: "NSString+Extension.swift").isEmpty)
    }

    @Test
    func nestedExtensionDoesntTrigger() throws {
        try #expect(validate(fileName: "Notification.Name+Extension.swift").isEmpty)
    }

    @Test
    func nestedTypeDoesntTrigger() throws {
        try #expect(validate(fileName: "Nested.MyType.swift").isEmpty)
    }

    @Test
    func multipleLevelsDeeplyNestedTypeDoesntTrigger() throws {
        try #expect(validate(fileName: "Multiple.Levels.Deeply.Nested.MyType.swift").isEmpty)
    }

    @Test
    func nestedTypeNotFullyQualifiedDoesntTrigger() throws {
        try #expect(validate(fileName: "MyType.swift").isEmpty)
    }

    @Test
    func nestedTypeNotFullyQualifiedDoesTriggerWithOverride() throws {
        try #expect(validate(fileName: "MyType.swift", requireFullyQualifiedNames: true).isNotEmpty)
    }

    @Test
    func nestedTypeSeparatorDoesntTrigger() throws {
        try #expect(validate(fileName: "NotificationName+Extension.swift", nestedTypeSeparator: "").isEmpty)
        try #expect(validate(fileName: "Notification__Name+Extension.swift", nestedTypeSeparator: "__").isEmpty)
    }

    @Test
    func wrongNestedTypeSeparatorDoesTrigger() throws {
        try #expect(validate(fileName: "Notification__Name+Extension.swift", nestedTypeSeparator: ".").isNotEmpty)
        try #expect(validate(fileName: "NotificationName+Extension.swift", nestedTypeSeparator: "__").isNotEmpty)
    }

    @Test
    func misspelledNameDoesTrigger() throws {
        try #expect(validate(fileName: "MyStructf.swift").count == 1)
    }

    @Test
    func misspelledNameDoesntTriggerWithOverride() throws {
        try #expect(validate(fileName: "MyStructf.swift", excluded: ["MyStructf.swift"]).isEmpty)
    }

    @Test
    func mainDoesTriggerWithoutOverride() throws {
        try #expect(validate(fileName: "main.swift", excluded: []).count == 1)
    }

    @Test
    func customSuffixPattern() throws {
        try #expect(validate(fileName: "BoolExtension.swift", suffixPattern: "Extensions?").isEmpty)
        try #expect(validate(fileName: "BoolExtensions.swift", suffixPattern: "Extensions?").isEmpty)
        try #expect(validate(fileName: "BoolExtensionTests.swift", suffixPattern: "Extensions?|\\+.*").isEmpty)
    }

    @Test
    func customPrefixPattern() throws {
        try #expect(validate(fileName: "ExtensionBool.swift", prefixPattern: "Extensions?").isEmpty)
        try #expect(validate(fileName: "ExtensionsBool.swift", prefixPattern: "Extensions?").isEmpty)
    }

    @Test
    func customPrefixAndSuffixPatterns() throws {
        try #expect(
            validate(
                fileName: "SLBoolExtension.swift",
                prefixPattern: "SL",
                suffixPattern: "Extensions?|\\+.*"
            ).isEmpty
        )

        try #expect(
            validate(
                fileName: "ExtensionBool+SwiftLint.swift",
                prefixPattern: "Extensions?",
                suffixPattern: "Extensions?|\\+.*"
            ).isEmpty
        )
    }

    @Test
    func excludedDoesntSupportRegex() throws {
        try #expect(
            validate(
                fileName: "main.swift",
                excluded: [".*"]
            ).isNotEmpty
        )
    }

    @Test
    func excludedPathPatternsSupportRegex() throws {
        try #expect(
            validate(
                fileName: "main.swift",
                excluded: [],
                excludedPaths: [".*"]
            ).isEmpty
        )

        try #expect(
            validate(
                fileName: "main.swift",
                excluded: [],
                excludedPaths: [".*.swift"]
            ).isEmpty
        )

        try #expect(
            validate(
                fileName: "main.swift",
                excluded: [],
                excludedPaths: [".*/FileNameRuleFixtures/.*"]
            ).isEmpty
        )
    }

    @Test
    func excludedPathPatternsWithRegexDoesntMatch() throws {
        try #expect(
            validate(
                fileName: "main.swift",
                excluded: [],
                excludedPaths: [".*/OtherFolder/.*", "MAIN\\.swift"]
            ).isNotEmpty
        )
    }

    @Test
    func invalidRegex() throws {
        #expect(throws: (any Error).self) {
            try validate(
                fileName: "NSString+Extension.swift",
                excluded: [],
                excludedPaths: ["("],
                prefixPattern: "",
                suffixPattern: ""
            )
        }
    }

    @Test
    func excludedPathPatternsWithMultipleRegexs() throws {
        #expect(throws: (any Error).self) {
            try validate(
                fileName: "main.swift",
                excluded: [],
                excludedPaths: ["/FileNameRuleFixtures/.*", "("]
            )
        }
        #expect(throws: (any Error).self) {
            try validate(
                fileName: "main.swift",
                excluded: [],
                excludedPaths: ["/FileNameRuleFixtures/.*", "(", ".*.swift"]
            )
        }
    }
}
