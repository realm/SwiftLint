//
//  ReporterTests.swift
//  SwiftLint
//
//  Created by JP Simard on 9/19/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation
import SwiftLintFramework
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
            XCTAssertEqual(reporter.identifier, reporterFromString(reporter.identifier).identifier)
        }
    }

    func stringFromFile(_ filename: String) -> String {
        let bundle: Bundle = Bundle(for:type(of: self).self)
        let resourceName = (filename as NSString).deletingPathExtension
        let resourceExtension = (filename as NSString).pathExtension
        let filePath: String? = bundle.path(forResource: resourceName, ofType: resourceExtension)
        let data: Data? = try? Data(contentsOf: URL(fileURLWithPath: filePath!))
        assert(data != nil)
        let string = String(data: data!, encoding: .utf8)
        assert(string != nil)
        return string!
    }

    func generateViolations() -> [StyleViolation] {
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
        XCTAssertEqual(result, expectedOutput)
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

    // swiftlint:disable:next function_body_length
    func testHTMLReporter() {
        let generatedHTML = HTMLReporter.generateReport(generateViolations())

        let formatter = DateFormatter()
        formatter.dateStyle = .short
        let dateString = formatter.string(from: Date())

        let v = Bundle(identifier: "io.realm.SwiftLintFramework")?
            .object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"

        let expectedHTML = "<!doctype html>\n" +
            "<html>\n" +
            "\t<head>\n" +
            "\t\t<title>Swiftlint Report</title>\n" +
            "\t\t<style type='text/css'>\n" +
            "\t\t\ttable {\n" +
            "\t\t\t\tborder: 1px solid gray;\n" +
            "\t\t\t\tborder-collapse: collapse;\n" +
            "\t\t\t\t-moz-box-shadow: 3px 3px 4px #AAA;\n" +
            "\t\t\t\t-webkit-box-shadow: 3px 3px 4px #AAA;\n" +
            "\t\t\t\tbox-shadow: 3px 3px 4px #AAA;\n" +
            "\t\t\t}\n" +
            "\t\ttd, th {\n" +
            "\t\t\t\tborder: 1px solid #D3D3D3;\n" +
            "\t\t\t\tpadding: 5px 10px 5px 10px;\n" +
            "\t\t}\n" +
            "\t\tth {\n" +
            "\t\t\tborder-bottom: 1px solid gray;\n" +
            "\t\t\tbackground-color: #29345C50;\n" +
            "\t\t}\n" +
            "\t\t.error, .warning {\n" +
            "\t\t\tbackground-color: #f0f099;\n" +
            "\t\t} .error{ color: #ff0000;}\n" +
            "\t\t.warning { color: #b36b00;\n" +
            "\t\t}\n" +
            "\t\t</style>\n" +
            "\t</head>\n" +
            "\t<body>\n" +
            "\t\t<h1>Swiftlint Report</h1>\n" +
            "\t\t<hr />\n" +
            "\t\t<h2>Violations</h2>\n" +
            "\t\t<table border=\"1\" style=\"vertical-align: top; height: 64px;\">\n" +
            "\t\t\t<thead>\n" +
            "\t\t\t\t<tr>\n" +
            "\t\t\t\t\t<th style=\"width: 60pt;\">\n" +
            "\t\t\t\t\t\t<b>Serial No.</b>\n" +
            "\t\t\t\t\t</th>\n" +
            "\t\t\t\t\t<th style=\"width: 500pt;\">\n" +
            "\t\t\t\t\t\t<b>File</b>\n" +
            "\t\t\t\t\t</th>\n" +
            "\t\t\t\t\t<th style=\"width: 60pt;\">\n" +
            "\t\t\t\t\t\t<b>Location</b>\n" +
            "\t\t\t\t\t</th>\n" +
            "\t\t\t\t\t<th style=\"width: 60pt;\">\n" +
            "\t\t\t\t\t\t<b>Severity</b>\n" +
            "\t\t\t\t\t</th>\n" +
            "\t\t\t\t\t<th style=\"width: 500pt;\">\n" +
            "\t\t\t\t\t\t<b>Message</b>\n" +
            "\t\t\t\t\t</th>\n" +
            "\t\t\t\t</tr>\n" +
            "\t\t\t</thead>\n" +
            "\t\t\t<tbody>\n" +
            "\t\t\t\t<tr>\n" +
            "\t\t\t\t\t<td align=\"right\">1</td>\n" +
            "\t\t\t\t\t<td>filename</td>\n" +
            "\t\t\t\t\t<td align=\"center\">1:2</td>\n" +
            "\t\t\t\t\t<td class='warning'>Warning</td>\n" +
            "\t\t\t\t\t<td>Violation Reason.</td>\n" +
            "\t\t\t\t</tr>\n" +
            "\t\t\t\t<tr>\n" +
            "\t\t\t\t\t<td align=\"right\">2</td>\n" +
            "\t\t\t\t\t<td>filename</td>\n" +
            "\t\t\t\t\t<td align=\"center\">1:2</td>\n" +
            "\t\t\t\t\t<td class='error'>Error</td>\n" +
            "\t\t\t\t\t<td>Violation Reason.</td>\n" +
            "\t\t\t\t</tr>\n" +
            "\t\t\t\t<tr>\n" +
            "\t\t\t\t\t<td align=\"right\">3</td>\n" +
            "\t\t\t\t\t<td>filename</td>\n" +
            "\t\t\t\t\t<td align=\"center\">1:2</td>\n" +
            "\t\t\t\t\t<td class='error'>Error</td>\n" +
            "\t\t\t\t\t<td>Shorthand syntactic sugar should be used" +
            ", i.e. [Int] instead of Array&lt;Int&gt;.</td>\n" +
            "\t\t\t\t</tr>\n" +
            "\t\t\t\t<tr>\n" +
            "\t\t\t\t\t<td align=\"right\">4</td>\n" +
            "\t\t\t\t\t<td>&lt;nopath&gt;</td>\n" +
            "\t\t\t\t\t<td align=\"center\">0:0</td>\n" +
            "\t\t\t\t\t<td class='error'>Error</td>\n" +
            "\t\t\t\t\t<td>Colons should be next to the identifier" +
            " when specifying a type.</td>\n" +
            "\t\t\t\t</tr>\n" +
            "\t\t\t</tbody>\n" +
            "\t\t</table>\n" +
            "\t\t<br/>\n" +
            "\t\t<h2>Summary</h2>\n" +
            "\t\t<table border=\"1\" style=\"vertical-align: top; height: 64px;\">\n" +
            "\t\t\t<tbody>\n" +
            "\t\t\t\t<tr>\n" +
            "\t\t\t\t\t<td>Total files with violations</td>\n" +
            "\t\t\t\t\t<td>1</td>\n" +
            "\t\t\t\t</tr>\n" +
            "\t\t\t\t<tr>\n" +
            "\t\t\t\t\t<td>Total warnings</td>\n" +
            "\t\t\t\t\t<td>1</td>\n" +
            "\t\t\t\t</tr>\n" +
            "\t\t\t\t<tr>\n" +
            "\t\t\t\t\t<td>Total errors</td>\n" +
            "\t\t\t\t\t<td>3</td>\n" +
            "\t\t\t\t</tr>\n" +
            "\t\t\t</tbody>\n" +
            "\t\t</table>\n" +
            "\t\t<hr />\n" +
            "\t\t<p>Created with <a href=\"https://github.com/realm/SwiftLint\">\n" +
            "\t\t\t<b>Swiftlint</b>\n" +
            "\t\t</a> " + v + " on: " + dateString + "</p>\n" +
            "\t</body>\n" +
        "</html>"

        XCTAssertEqual(generatedHTML, expectedHTML)
    }
}

extension ReporterTests {
    static var allTests: [(String, (ReporterTests) -> () throws -> Void)] {
        return [
            ("testReporterFromString", testReporterFromString),
            ("testXcodeReporter", testXcodeReporter),
            ("testEmojiReporter", testEmojiReporter),
            // Fails on Linux
            // ("testJSONReporter", testJSONReporter),
            ("testCSVReporter", testCSVReporter),
            ("testCheckstyleReporter", testCheckstyleReporter),
            ("testJunitReporter", testJunitReporter),
            ("testHTMLReporter", testHTMLReporter)
        ]
    }
}
