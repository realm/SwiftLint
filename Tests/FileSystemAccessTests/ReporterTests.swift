import Foundation
import SourceKittenFramework
import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules
@testable import SwiftLintFramework

extension FileSystemAccessTestSuite.ReporterTests {
    private static var violations: [StyleViolation] {
        [
            StyleViolation(
                ruleDescription: LineLengthRule.description,
                location: Location(file: "filename", line: 1, character: 1),
                reason: "Violation Reason 1"
            ),
            StyleViolation(
                ruleDescription: LineLengthRule.description,
                severity: .error,
                location: Location(file: "filename", line: 1),
                reason: "Violation Reason 2"
            ),
            StyleViolation(
                ruleDescription: SyntacticSugarRule.description,
                severity: .error,
                location: Location(
                    file: FileManager.default.currentDirectoryPath + "/path/file.swift",
                    line: 1,
                    character: 2
                ),
                reason: "Shorthand syntactic sugar should be used, i.e. [Int] instead of Array<Int>"),
            StyleViolation(
                ruleDescription: ColonRule.description,
                severity: .error,
                location: Location(file: nil),
                reason: nil
            ),
        ]
    }

    @Test
    func reporterFromString() {
        for reporter in reportersList {
            #expect(reporter.identifier == reporterFrom(identifier: reporter.identifier).identifier)
        }
    }

    @Test
    func xcodeReporter() throws {
        try assertEqualContent(
            referenceFile: "CannedXcodeReporterOutput.txt",
            reporterType: XcodeReporter.self
        )
    }

    @Test
    func emojiReporter() throws {
        try assertEqualContent(
            referenceFile: "CannedEmojiReporterOutput.txt",
            reporterType: EmojiReporter.self
        )
    }

    @Test
    func gitHubActionsLoggingReporter() throws {
        try assertEqualContent(
            referenceFile: "CannedGitHubActionsLoggingReporterOutput.txt",
            reporterType: GitHubActionsLoggingReporter.self
        )
    }

    @Test
    func gitLabJUnitReporter() throws {
        try assertEqualContent(
            referenceFile: "CannedGitLabJUnitReporterOutput.xml",
            reporterType: GitLabJUnitReporter.self
        )
    }

    private func jsonValue(_ jsonString: String) throws -> NSObject {
        let data = jsonString.data(using: .utf8)!
        let result = try JSONSerialization.jsonObject(with: data, options: [])
        if let dict = (result as? [String: Any])?.bridge() {
            return dict
        }
        if let array = (result as? [Any])?.bridge() {
            return array
        }
        queuedFatalError("Unexpected value in JSON: \(result)")
    }

    @Test
    func jsonReporter() throws {
        try assertEqualContent(
            referenceFile: "CannedJSONReporterOutput.json",
            reporterType: JSONReporter.self,
            stringConverter: { try jsonValue($0) }
        )
    }

    @Test
    func cSVReporter() throws {
        try assertEqualContent(
            referenceFile: "CannedCSVReporterOutput.csv",
            reporterType: CSVReporter.self
        )
    }

    @Test
    func checkstyleReporter() throws {
        try assertEqualContent(
            referenceFile: "CannedCheckstyleReporterOutput.xml",
            reporterType: CheckstyleReporter.self
        )
    }

    @Test
    func codeClimateReporter() throws {
        try assertEqualContent(
            referenceFile: "CannedCodeClimateReporterOutput.json",
            reporterType: CodeClimateReporter.self
        )
    }

    @Test
    func sarifReporter() throws {
        try assertEqualContent(
            referenceFile: "CannedSARIFReporterOutput.json",
            reporterType: SARIFReporter.self
        )
    }

    @Test
    func junitReporter() throws {
        try assertEqualContent(
            referenceFile: "CannedJunitReporterOutput.xml",
            reporterType: JUnitReporter.self
        )
    }

    @Test
    func htmlReporter() throws {
        try assertEqualContent(
            referenceFile: "CannedHTMLReporterOutput.html",
            reporterType: HTMLReporter.self
        )
    }

    @Test
    func sonarQubeReporter() throws {
        try assertEqualContent(
            referenceFile: "CannedSonarQubeReporterOutput.json",
            reporterType: SonarQubeReporter.self,
            stringConverter: { try jsonValue($0) }
        )
    }

    @Test
    func markdownReporter() throws {
        try assertEqualContent(
            referenceFile: "CannedMarkdownReporterOutput.md",
            reporterType: MarkdownReporter.self
        )
    }

    @Test
    func relativePathReporter() throws {
        try assertEqualContent(
            referenceFile: "CannedRelativePathReporterOutput.txt",
            reporterType: RelativePathReporter.self
        )
    }

    @Test
    func relativePathReporterPaths() {
        let relativePath = "filename"
        let absolutePath = FileManager.default.currentDirectoryPath + "/" + relativePath
        let location = Location(file: absolutePath, line: 1, character: 2)
        let violation = StyleViolation(
            ruleDescription: LineLengthRule.description,
            location: location,
            reason: "Violation Reason")
        let result = RelativePathReporter.generateReport([violation])
        #expect(!result.contains(absolutePath))
        #expect(result.contains(relativePath))
    }

    @Test
    func summaryReporter() throws {
        let expectedOutput = try stringFromFile("CannedSummaryReporterOutput.txt")
            .trimmingTrailingCharacters(in: .whitespacesAndNewlines)
        let correctableViolation = StyleViolation(
            ruleDescription: VerticalWhitespaceOpeningBracesRule.description,
            location: Location(file: "filename", line: 1, character: 2),
            reason: "Violation Reason"
        )
        let result = SummaryReporter.generateReport(Self.violations + [correctableViolation])
        #expect(result == expectedOutput)
    }

    @Test
    func summaryReporterWithNoViolations() throws {
        let expectedOutput = try stringFromFile("CannedSummaryReporterNoViolationsOutput.txt")
            .trimmingTrailingCharacters(in: .whitespacesAndNewlines)
        let result = SummaryReporter.generateReport([])
        #expect(result == expectedOutput)
    }

    private func assertEqualContent(
        referenceFile: String,
        reporterType: any Reporter.Type,
        stringConverter: (String) throws -> some Equatable = { $0 },
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        let reference = try stringFromFile(referenceFile).replacingOccurrences(
            of: "${CURRENT_WORKING_DIRECTORY}",
            with: FileManager.default.currentDirectoryPath
        ).replacingOccurrences(
            of: "${SWIFTLINT_VERSION}",
            with: SwiftLintFramework.Version.current.value
        ).replacingOccurrences(
            of: "${TODAYS_DATE}",
            with: dateFormatter.string(from: Date())
        )
        let reporterOutput = reporterType.generateReport(Self.violations)
        let convertedReference = try stringConverter(reference)
        let convertedReporterOutput = try stringConverter(reporterOutput)
        if convertedReference != convertedReporterOutput {
            let referenceURL = URL(fileURLWithPath: "\(TestResources.path())/\(referenceFile)")
            try reporterOutput.replacingOccurrences(
                of: FileManager.default.currentDirectoryPath,
                with: "${CURRENT_WORKING_DIRECTORY}"
            ).replacingOccurrences(
                of: SwiftLintFramework.Version.current.value,
                with: "${SWIFTLINT_VERSION}"
            ).replacingOccurrences(
                of: dateFormatter.string(from: Date()),
                with: "${TODAYS_DATE}"
            )
            .write(to: referenceURL, atomically: true, encoding: .utf8)
        }
        #expect(
            convertedReference == convertedReporterOutput,
            sourceLocation: SourceLocation(fileID: #fileID, filePath: file.description, line: Int(line), column: 1))
    }

    private func stringFromFile(_ filename: String) throws -> String {
        try #require(SwiftLintFile(path: TestResources.path() + "/" + filename)).contents
    }
}
