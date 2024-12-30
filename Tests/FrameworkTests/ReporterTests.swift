import Foundation
import SourceKittenFramework
@testable import SwiftLintBuiltInRules
@testable import SwiftLintFramework
import TestHelpers
import XCTest

final class ReporterTests: SwiftLintTestCase {
    private let violations = [
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

    func testReporterFromString() {
        for reporter in reportersList {
            XCTAssertEqual(reporter.identifier, reporterFrom(identifier: reporter.identifier).identifier)
        }
    }

    private func stringFromFile(_ filename: String) -> String {
        SwiftLintFile(path: "\(TestResources.path())/\(filename)")!.contents
    }

    func testXcodeReporter() throws {
        try assertEqualContent(
            referenceFile: "CannedXcodeReporterOutput.txt",
            reporterType: XcodeReporter.self
        )
    }

    func testEmojiReporter() throws {
        try assertEqualContent(
            referenceFile: "CannedEmojiReporterOutput.txt",
            reporterType: EmojiReporter.self
        )
    }

    func testGitHubActionsLoggingReporter() throws {
        try assertEqualContent(
            referenceFile: "CannedGitHubActionsLoggingReporterOutput.txt",
            reporterType: GitHubActionsLoggingReporter.self
        )
    }

    func testGitLabJUnitReporter() throws {
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

    func testJSONReporter() throws {
        try assertEqualContent(
            referenceFile: "CannedJSONReporterOutput.json",
            reporterType: JSONReporter.self,
            stringConverter: { try jsonValue($0) }
        )
    }

    func testCSVReporter() throws {
        try assertEqualContent(
            referenceFile: "CannedCSVReporterOutput.csv",
            reporterType: CSVReporter.self
        )
    }

    func testCheckstyleReporter() throws {
        try assertEqualContent(
            referenceFile: "CannedCheckstyleReporterOutput.xml",
            reporterType: CheckstyleReporter.self
        )
    }

    func testCodeClimateReporter() throws {
        try assertEqualContent(
            referenceFile: "CannedCodeClimateReporterOutput.json",
            reporterType: CodeClimateReporter.self
        )
    }

    func testSARIFReporter() throws {
        try assertEqualContent(
            referenceFile: "CannedSARIFReporterOutput.json",
            reporterType: SARIFReporter.self
        )
    }

    func testJunitReporter() throws {
        try assertEqualContent(
            referenceFile: "CannedJunitReporterOutput.xml",
            reporterType: JUnitReporter.self
        )
    }

    func testHTMLReporter() throws {
        try assertEqualContent(
            referenceFile: "CannedHTMLReporterOutput.html",
            reporterType: HTMLReporter.self
        )
    }

    func testSonarQubeReporter() throws {
        try assertEqualContent(
            referenceFile: "CannedSonarQubeReporterOutput.json",
            reporterType: SonarQubeReporter.self,
            stringConverter: { try jsonValue($0) }
        )
    }

    func testMarkdownReporter() throws {
        try assertEqualContent(
            referenceFile: "CannedMarkdownReporterOutput.md",
            reporterType: MarkdownReporter.self
        )
    }

    func testRelativePathReporter() throws {
        try assertEqualContent(
            referenceFile: "CannedRelativePathReporterOutput.txt",
            reporterType: RelativePathReporter.self
        )
    }

    func testRelativePathReporterPaths() {
        let relativePath = "filename"
        let absolutePath = FileManager.default.currentDirectoryPath + "/" + relativePath
        let location = Location(file: absolutePath, line: 1, character: 2)
        let violation = StyleViolation(ruleDescription: LineLengthRule.description,
                                       location: location,
                                       reason: "Violation Reason")
        let result = RelativePathReporter.generateReport([violation])
        XCTAssertFalse(result.contains(absolutePath))
        XCTAssertTrue(result.contains(relativePath))
    }

    func testSummaryReporter() {
        let expectedOutput = stringFromFile("CannedSummaryReporterOutput.txt")
            .trimmingTrailingCharacters(in: .whitespacesAndNewlines)
        let correctableViolation = StyleViolation(
            ruleDescription: VerticalWhitespaceOpeningBracesRule.description,
            location: Location(file: "filename", line: 1, character: 2),
            reason: "Violation Reason"
        )
        let result = SummaryReporter.generateReport(violations + [correctableViolation])
        XCTAssertEqual(result, expectedOutput)
    }

    func testSummaryReporterWithNoViolations() {
        let expectedOutput = stringFromFile("CannedSummaryReporterNoViolationsOutput.txt")
            .trimmingTrailingCharacters(in: .whitespacesAndNewlines)
        let result = SummaryReporter.generateReport([])
        XCTAssertEqual(result, expectedOutput)
    }

    private func assertEqualContent(referenceFile: String,
                                    reporterType: any Reporter.Type,
                                    stringConverter: (String) throws -> some Equatable = { $0 },
                                    file: StaticString = #filePath,
                                    line: UInt = #line) throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        let reference = stringFromFile(referenceFile).replacingOccurrences(
            of: "${CURRENT_WORKING_DIRECTORY}",
            with: FileManager.default.currentDirectoryPath
        ).replacingOccurrences(
            of: "${SWIFTLINT_VERSION}",
            with: SwiftLintFramework.Version.current.value
        ).replacingOccurrences(
            of: "${TODAYS_DATE}",
            with: dateFormatter.string(from: Date())
        )
        let reporterOutput = reporterType.generateReport(violations)
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
        XCTAssertEqual(convertedReference, convertedReporterOutput, file: file, line: line)
    }
}
