import SwiftLintCore
import TestHelpers
import Testing

@Suite
struct RegexConfigurationTests {
    @Test
    func shouldValidateIsTrueByDefault() {
        let config = RegexConfiguration<MockRule>(identifier: "example")
        #expect(config.shouldValidate(filePath: "App/file.swift".url()))
    }

    @Test
    func shouldValidateWithSingleExluded() throws {
        var config = RegexConfiguration<MockRule>(identifier: "example")
        try config.apply(configuration: [
            "regex": "try!",
            "excluded": "ExcludedFolder/.*\\.swift",
        ])

        #expect(!config.shouldValidate(filePath: "ExcludedFolder/file.swift".url()))
        #expect(config.shouldValidate(filePath: "App/file.swift".url()))
    }

    @Test
    func shouldValidateWithArrayExluded() throws {
        var config = RegexConfiguration<MockRule>(identifier: "example")
        try config.apply(configuration: [
            "regex": "try!",
            "excluded": [
                "ExcludedFolder/.*\\.swift",
                "MyFramework/ExcludedFolder/.*\\.swift",
            ] as Any,
        ])

        #expect(!config.shouldValidate(filePath: "ExcludedFolder/file.swift".url()))
        #expect(!config.shouldValidate(filePath: "MyFramework/ExcludedFolder/file.swift".url()))
        #expect(config.shouldValidate(filePath: "App/file.swift".url()))
    }

    @Test
    func shouldValidateWithSingleIncluded() throws {
        var config = RegexConfiguration<MockRule>(identifier: "example")
        try config.apply(configuration: [
            "regex": "try!",
            "included": "App/.*\\.swift",
        ])

        #expect(!config.shouldValidate(filePath: "Tests/file.swift".url()))
        #expect(!config.shouldValidate(filePath: "MyFramework/Tests/file.swift".url()))
        #expect(config.shouldValidate(filePath: "App/file.swift".url()))
    }

    @Test
    func shouldValidateWithArrayIncluded() throws {
        var config = RegexConfiguration<MockRule>(identifier: "example")
        try config.apply(configuration: [
            "regex": "try!",
            "included": [
                "App/.*\\.swift",
                "MyFramework/.*\\.swift",
            ] as Any,
        ])

        #expect(!config.shouldValidate(filePath: "Tests/file.swift".url()))
        #expect(config.shouldValidate(filePath: "App/file.swift".url()))
        #expect(config.shouldValidate(filePath: "MyFramework/file.swift".url()))
    }

    @Test
    func shouldValidateWithIncludedAndExcluded() throws {
        var config = RegexConfiguration<MockRule>(identifier: "example")
        try config.apply(configuration: [
            "regex": "try!",
            "included": [
                "App/.*\\.swift",
                "MyFramework/.*\\.swift",
            ] as Any,
            "excluded": [
                "ExcludedFolder/.*\\.swift",
                "App/Fixtures/.*\\.swift",
            ] as Any,
        ])

        #expect(config.shouldValidate(filePath: "App/file.swift".url()))
        #expect(config.shouldValidate(filePath: "MyFramework/file.swift".url()))

        #expect(!config.shouldValidate(filePath: "App/Fixtures/file.swift".url()))
        #expect(!config.shouldValidate(filePath: "ExcludedFolder/file.swift".url()))
        #expect(!config.shouldValidate(filePath: "MyFramework/ExcludedFolder/file.swift".url()))
    }
}
