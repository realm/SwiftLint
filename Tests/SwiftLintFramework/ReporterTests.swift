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

    func generateViolations() -> [StyleViolation] {
        let location = Location(file: "filename", line: 1, character: 2)
        return [
            StyleViolation(ruleDescription: LineLengthRule.description,
                location: location,
                reason: "Violation Reason."),
            StyleViolation(ruleDescription: LineLengthRule.description,
                severity: .Error,
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

    func testHTMLReporter() {
        let generatedHTML = HTMLReporter.generateReport(generateViolations())

        let formatter = NSDateFormatter()
        formatter.dateStyle = .ShortStyle
        let dateString = formatter.stringFromDate(NSDate())

        let originalHTML = "<!doctype html><html><head><title>Swiftlint Report</title><style type='text/css'>table { border: 1px solid gray; border-collapse: collapse; -moz-box-shadow: 3px 3px 4px #AAA; -webkit-box-shadow: 3px 3px 4px #AAA; box-shadow: 3px 3px 4px #AAA; } td, th { border: 1px solid #D3D3D3; padding: 5px 10px 5px 10px; } th { border-bottom: 1px solid gray; background-color: #29345C50; } .error, .warning {background-color: #f0f099;} .error{ color: #ff0000;} .warning { color: #b36b00;}</style></head><body><h1>Swiftlint Report</h1><hr /><h2>Violations</h2><table border=\"1\" style=\"vertical-align: top; height: 64px;\"><thead><tr><th style=\"width: 60pt;\"><b>Serial No.</b></th><th style=\"width: 500pt;\"><b>File</b></th><th style=\"width: 60pt;\"><b>Location</b></th><th style=\"width: 60pt;\"><b>Severity</b></th><th style=\"width: 500pt;\"><b>Message</b></th></tr></thead><tbody><tr><td align=\"right\">1</td><td>filename</td><td align=\"center\">1:2</td><td class='warning'>Warning </td><td>Violation Reason.</td></tr><tr><td align=\"right\">2</td><td>filename</td><td align=\"center\">1:2</td><td class='error'>Error </td><td>Violation Reason.</td></tr></tbody></table><br/><h2>Summary</h2><table border=\"1\" style=\"vertical-align: top; height: 64px;\"><tbody><tr><td>Total files with violations</td><td>1</td></tr><tr><td>Total warnings</td><td>1</td></tr><tr><td>Total errors</td><td>1</td></tr></tbody></table><hr /><p>Created with <a href=\"https://github.com/realm/SwiftLint\"><b>Swiftlint</b></a> 0.12.0 on: \(dateString)</p></body></html>"// swiftlint:disable:this line_length
         XCTAssertEqual(generatedHTML, originalHTML)
    }
}
