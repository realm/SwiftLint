//
//  ReporterTests.swift
//  SwiftLint
//
//  Created by JP Simard on 9/19/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework
@testable import SwiftLintFramework
import XCTest

class ReporterTests: XCTestCase {

    func testReporterFromString() {
        let reporters: [Reporter.Type] = [
            XcodeReporter.self,
            JSONReporter.self,
            CSVReporter.self,
            CheckstyleReporter.self,
            JUnitReporter.self,
            HTMLReporter.self,
            EmojiReporter.self
        ]
        for reporter in reporters {
            XCTAssertEqual(reporter.identifier, reporterFrom(identifier: reporter.identifier).identifier)
        }
    }

    private func stringFromFile(_ filename: String) -> String {
        return File(path: "\(bundlePath)/\(filename)")!.contents
    }

    private func generateViolations() -> [StyleViolation] {
        let location = Location(file: "filename", line: 1, character: 2)
        return [
            StyleViolation(ruleDescription: LineLengthRule.description,
                location: location,
                reason: "Violation Reason."),
            StyleViolation(ruleDescription: LineLengthRule.description,
                severity: .error,
                location: location,
                reason: "Violation Reason."),
            StyleViolation(ruleDescription: SyntacticSugarRule.description,
                severity: .error,
                location: location,
                reason: "Shorthand syntactic sugar should be used" +
                ", i.e. [Int] instead of Array<Int>."),
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

    func testJSONReporter() {
        let expectedOutput = stringFromFile("CannedJSONReporterOutput.json")
        let result = JSONReporter.generateReport(generateViolations())
        func jsonValue(_ jsonString: String) -> NSObject {
            let data = jsonString.data(using: .utf8)!
            // swiftlint:disable:next force_try
            let result = try! JSONSerialization.jsonObject(with: data, options: [])
            if let dict = (result as? [String: Any])?.bridge() {
                return dict
            } else if let array = (result as? [Any])?.bridge() {
                return array
            }
            fatalError()
        }
        XCTAssertEqual(jsonValue(result), jsonValue(expectedOutput))
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
}

extension ReporterTests {
    static var allTests: [(String, (ReporterTests) -> () throws -> Void)] {
        return [
            ("testReporterFromString", testReporterFromString),
            ("testXcodeReporter", testXcodeReporter),
            ("testEmojiReporter", testEmojiReporter),
            ("testJSONReporter", testJSONReporter),
            ("testCSVReporter", testCSVReporter),
            ("testCheckstyleReporter", testCheckstyleReporter),
            ("testJunitReporter", testJunitReporter),
            ("testHTMLReporter", testHTMLReporter)
        ]
    }
}
