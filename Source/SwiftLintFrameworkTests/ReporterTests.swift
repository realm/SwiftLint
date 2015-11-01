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
        let rule: Rule = LineLengthRule()
        return [
            StyleViolation(type: .Length,
                location: Location(file: "filename", line: 1, character: 2),
                severity: .Warning,
                reason: "Violation Reason.",
                rule: rule),
            StyleViolation(type: .Length,
                location: Location(file: "filename", line: 1, character: 2),
                severity: .Error,
                reason: "Violation Reason.",
                rule: rule)
        ]
    }

    func testXcodeReporter() {
        XCTAssertEqual(
            XcodeReporter.generateReport(generateViolations()),
            "filename:1:2: warning: Length Violation: Violation Reason. (line_length)\n" +
            "filename:1:2: error: Length Violation: Violation Reason. (line_length)"
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
                "    \"type\" : \"Length\"\n" +
                "  },\n" +
                "  {\n" +
                "    \"reason\" : \"Violation Reason.\",\n" +
                "    \"character\" : 2,\n" +
                "    \"file\" : \"filename\",\n" +
                "    \"rule_id\" : \"line_length\",\n" +
                "    \"line\" : 1,\n" +
                "    \"severity\" : \"Error\",\n" +
                "    \"type\" : \"Length\"\n" +
                "  }\n" +
            "]"
        )
    }

    func testCSVReporter() {
        XCTAssertEqual(
            CSVReporter.generateReport(generateViolations()),
            "file,line,character,severity,type,reason,rule_id," +
            "filename,1,2,Warning,Length,Violation Reason.,line_length," +
            "filename,1,2,Error,Length,Violation Reason.,line_length"
        )
    }
}
