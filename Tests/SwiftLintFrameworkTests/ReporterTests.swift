import Foundation
import SourceKittenFramework
@testable import SwiftLintBuiltInRules
@testable import SwiftLintCore
import XCTest

class ReporterTests: SwiftLintTestCase {
    func testReporterFromString() {
        for reporter in reportersList {
            XCTAssertEqual(reporter.identifier, reporterFrom(identifier: reporter.identifier).identifier)
        }
    }

    private func stringFromFile(_ filename: String) -> String {
        return SwiftLintFile(path: "\(testResourcesPath)/\(filename)")!.contents
    }

    private func generateViolations() -> [StyleViolation] {
        let location = Location(file: "filename", line: 1, character: 2)
        return [
            StyleViolation(ruleDescription: LineLengthRule.description,
                           location: location,
                           reason: "Violation Reason"),
            StyleViolation(ruleDescription: LineLengthRule.description,
                           severity: .error,
                           location: location,
                           reason: "Violation Reason"),
            StyleViolation(ruleDescription: SyntacticSugarRule.description,
                           severity: .error,
                           location: location,
                           reason: "Shorthand syntactic sugar should be used" +
                                   ", i.e. [Int] instead of Array<Int>"),
            StyleViolation(ruleDescription: ColonRule.description,
                           severity: .error,
                           location: Location(file: nil),
                           reason: nil)
        ]
    }

    func testXcodeReporter() {
        let expectedOutput = stringFromFile("CannedXcodeReporterOutput.txt")
        let result = XcodeReporter.generateReport(generateViolations())
        XCTAssertEqual(result, expectedOutput)
    }

    func testEmojiReporter() {
        let expectedOutput = stringFromFile("CannedEmojiReporterOutput.txt")
        let result = EmojiReporter.generateReport(generateViolations())
        XCTAssertEqual(result, expectedOutput)
    }

    func testGitHubActionsLoggingReporter() {
        let expectedOutput = stringFromFile("CannedGitHubActionsLoggingReporterOutput.txt")
        let result = GitHubActionsLoggingReporter.generateReport(generateViolations())
        XCTAssertEqual(result, expectedOutput)
    }

    func testGitLabJUnitReporter() {
        let expectedOutput = stringFromFile("CannedGitLabJUnitReporterOutput.xml")
        let result = GitLabJUnitReporter.generateReport(generateViolations())
        XCTAssertEqual(result, expectedOutput)
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
        let expectedOutput = stringFromFile("CannedJSONReporterOutput.json")
        let result = JSONReporter.generateReport(generateViolations())
        XCTAssertEqual(try jsonValue(result), try jsonValue(expectedOutput))
    }

    func testCSVReporter() {
        let expectedOutput = stringFromFile("CannedCSVReporterOutput.csv")
        let result = CSVReporter.generateReport(generateViolations())
        XCTAssertEqual(result, expectedOutput)
    }

    func testCheckstyleReporter() {
        let expectedOutput = stringFromFile("CannedCheckstyleReporterOutput.xml")
        let result = CheckstyleReporter.generateReport(generateViolations())
        XCTAssertEqual(result, expectedOutput)
    }

    func testCodeClimateReporter() {
        let expectedOutput = stringFromFile("CannedCodeClimateReporterOutput.json")
        let result = CodeClimateReporter.generateReport(generateViolations())
        XCTAssertEqual(result, expectedOutput)
    }

    func testSARIFReporter() {
        let expectedOutput = stringFromFile("CannedSARIFReporterOutput.json")

        var expectedDictionary: [String: Any] = [:]
        do {
            expectedDictionary = try JSONSerialization.jsonObject(with: Data(expectedOutput.utf8),
                                                                  options: .allowFragments) as? [String: Any] ?? [:]
        } catch {
            print(error)
        }

        let result = SARIFReporter.generateReport(generateViolations())

        var resultDictionary: [String: Any] = [:]
        do {
            resultDictionary = try JSONSerialization.jsonObject(with: Data(result.utf8),
                                                                options: .allowFragments) as? [String: Any] ?? [:]
        } catch {
            print(error)
        }

        XCTAssertTrue(areEqual(expectedDictionary, resultDictionary))
    }

    func testJunitReporter() {
        let expectedOutput = stringFromFile("CannedJunitReporterOutput.xml")
        let result = JUnitReporter.generateReport(generateViolations())
        XCTAssertEqual(result, expectedOutput)
    }

    func testHTMLReporter() {
        let expectedOutput = stringFromFile("CannedHTMLReporterOutput.html")
        let result = HTMLReporter.generateReport(
            generateViolations(),
            swiftlintVersion: "1.2.3",
            dateString: "13/12/2016"
        )
        XCTAssertEqual(result, expectedOutput)
    }

    func testSonarQubeReporter() {
        let expectedOutput = stringFromFile("CannedSonarQubeReporterOutput.json")
        let result = SonarQubeReporter.generateReport(generateViolations())
        XCTAssertEqual(try jsonValue(result), try jsonValue(expectedOutput))
    }

    func testMarkdownReporter() {
        let expectedOutput = stringFromFile("CannedMarkdownReporterOutput.md")
        let result = MarkdownReporter.generateReport(generateViolations())
        XCTAssertEqual(result, expectedOutput)
    }

    func testRelativePathReporter() {
        let expectedOutput = stringFromFile("CannedRelativePathReporterOutput.txt")
        let result = RelativePathReporter.generateReport(generateViolations())
        XCTAssertEqual(result, expectedOutput)
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
        let result = SummaryReporter.generateReport(generateViolations() + [correctableViolation])
        XCTAssertEqual(result, expectedOutput)
    }

    func testSummaryReporterWithNoViolations() {
        let expectedOutput = stringFromFile("CannedSummaryReporterNoViolationsOutput.txt")
            .trimmingTrailingCharacters(in: .whitespacesAndNewlines)
        let result = SummaryReporter.generateReport([])
        XCTAssertEqual(result, expectedOutput)
    }
}

/// Utilities used to compare [String: Any] dictionaries
private func areEqual (_ left: Any, _ right: Any) -> Bool {
    if  type(of: left) == type(of: right) &&
        String(describing: left) == String(describing: right) { return true }
    if let left = left as? [Any], let right = right as? [Any] { return left == right }
    if let left = left as? [AnyHashable: Any], let right = right as? [AnyHashable: Any] { return left == right }
    return false
}

private extension Array where Element: Any {
    static func != (left: [Element], right: [Element]) -> Bool { return !(left == right) }
    static func == (left: [Element], right: [Element]) -> Bool {
        if left.count != right.count { return false }
        var right = right
        loop: for leftValue in left {
            for (rightIndex, rightValue) in right.enumerated() where areEqual(leftValue, rightValue) {
                right.remove(at: rightIndex)
                continue loop
            }
            return false
        }
        return true
    }
}

private extension Dictionary where Value: Any {
    static func != (left: [Key: Value], right: [Key: Value]) -> Bool { return !(left == right) }
    static func == (left: [Key: Value], right: [Key: Value]) -> Bool {
        if left.count != right.count { return false }
        for element in left {
            guard   let rightValue = right[element.key],
                areEqual(rightValue, element.value) else { return false }
        }
        return true
    }
}
