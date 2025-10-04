import SourceKittenFramework
import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

private let fixturesDirectory = "\(TestResources.path())/FileNameNoSpaceRuleFixtures"

@Suite(.rulesRegistered)
struct FileNameNoSpaceRuleTests {
    private func validate(fileName: String, excludedOverride: [String]? = nil) throws -> [StyleViolation] {
        let file = SwiftLintFile(path: fixturesDirectory.stringByAppendingPathComponent(fileName))!
        let rule: FileNameNoSpaceRule
        if let excluded = excludedOverride {
            rule = try FileNameNoSpaceRule(configuration: ["excluded": excluded])
        } else {
            rule = FileNameNoSpaceRule()
        }

        return rule.validate(file: file)
    }

    @Test
    func fileNameDoesntTrigger() throws {
        try #expect(validate(fileName: "File.swift").isEmpty)
    }

    @Test
    func fileWithSpaceDoesTrigger() throws {
        try #expect(validate(fileName: "File Name.swift").count == 1)
    }

    @Test
    func extensionNameDoesntTrigger() throws {
        try #expect(validate(fileName: "File+Extension.swift").isEmpty)
    }

    @Test
    func extensionWithSpaceDoesTrigger() throws {
        try #expect(validate(fileName: "File+Test Extension.swift").count == 1)
    }

    @Test
    func customExcludedList() throws {
        try #expect(
            validate(
                fileName: "File+Test Extension.swift",
                excludedOverride: ["File+Test Extension.swift"]
            ).isEmpty
        )
    }
}
