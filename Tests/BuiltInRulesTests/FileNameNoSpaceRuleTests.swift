import Foundation
import SourceKittenFramework
import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

private let fixturesDirectory = "\(TestResources.path())/FileNameNoSpaceRuleFixtures"

@Suite(.rulesRegistered)
struct FileNameNoSpaceRuleTests {
    private func validate(fileName: String, excludedOverride: [String]? = nil) throws -> [StyleViolation] {
        let file = TestResources.path()
            .appending(path: "FileNameNoSpaceRuleFixtures", directoryHint: .isDirectory)
            .appending(path: fileName, directoryHint: .notDirectory)
        let rule =
            if let excluded = excludedOverride {
                try FileNameNoSpaceRule(configuration: ["excluded": excluded])
            } else {
                FileNameNoSpaceRule()
            }
        return rule.validate(file: SwiftLintFile(path: file)!)
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
