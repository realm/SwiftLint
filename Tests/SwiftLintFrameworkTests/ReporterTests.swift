//
//  ReporterTests.swift
//  SwiftLint
//
//  Created by JP Simard on 9/19/15.
//  Copyright © 2015 Realm. All rights reserved.
//

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
            HTMLReporter.self
        ]
        for reporter in reporters {
            XCTAssertEqual(reporter.identifier, reporterFromString(reporter.identifier).identifier)
        }
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
                reason: "Violation Reason.")
        ]
    }

    func testXcodeReporter() {
        XCTAssertEqual(
            XcodeReporter.generateReport(generateViolations()),
            "filename:1:2: warning: Line Length Violation: Violation Reason. (line_length)\n" +
            "filename:1:2: error: Line Length Violation: Violation Reason. (line_length)"
        )
    }

    func testJSONReporter() {
        XCTAssertEqual(
            JSONReporter.generateReport(generateViolations()),
            "[\n" +
                "  {\n" +
                "    \"reason\" : \"Violation Reason.\",\n" +
                "    \"character\" : 2,\n" +
                "    \"file\" : \"filename\",\n" +
                "    \"rule_id\" : \"line_length\",\n" +
                "    \"line\" : 1,\n" +
                "    \"severity\" : \"Warning\",\n" +
                "    \"type\" : \"Line Length\"\n" +
                "  },\n" +
                "  {\n" +
                "    \"reason\" : \"Violation Reason.\",\n" +
                "    \"character\" : 2,\n" +
                "    \"file\" : \"filename\",\n" +
                "    \"rule_id\" : \"line_length\",\n" +
                "    \"line\" : 1,\n" +
                "    \"severity\" : \"Error\",\n" +
                "    \"type\" : \"Line Length\"\n" +
                "  }\n" +
            "]"
        )
    }

    func testCSVReporter() {
        XCTAssertEqual(
            CSVReporter.generateReport(generateViolations()),
            "file,line,character,severity,type,reason,rule_id," +
            "filename,1,2,Warning,Line Length,Violation Reason.,line_length," +
            "filename,1,2,Error,Line Length,Violation Reason.,line_length"
        )
    }

    func testCheckstyleReporter() {
        XCTAssertEqual(
            CheckstyleReporter.generateReport(generateViolations()),
            "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<checkstyle version=\"4.3\">\n" +
            "\t<file name=\"filename\">\n\t\t<error line=\"1\" column=\"2\" severity=\"warning\" " +
            "message=\"Violation Reason.\"/>\n\t</file>\n" +
            "\t<file name=\"filename\">\n\t\t<error line=\"1\" column=\"2\" severity=\"error\" " +
            "message=\"Violation Reason.\"/>\n\t</file>\n" +
            "</checkstyle>"
        )
    }

    func testJunitReporter() {
        XCTAssertEqual(
            JUnitReporter.generateReport(generateViolations()),
            "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<testsuites><testsuite>\n" +
                "\t<testcase classname=\'Formatting Test\' name=\'filename\'>\n" +
                    "<failure message=\'Violation Reason.\'>warning:\nLine:1 </failure>" +
                "\t</testcase>\n" +
                "\t<testcase classname=\'Formatting Test\' name=\'filename\'>\n" +
                    "<failure message=\'Violation Reason.\'>error:\nLine:1 </failure>" +
                "\t</testcase>\n</testsuite></testsuites>"
        )
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
            "\t\t\t\t\t<td>1</td>\n" +
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
