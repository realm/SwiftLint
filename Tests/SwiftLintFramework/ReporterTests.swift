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
}
