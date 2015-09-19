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
        return [
            StyleViolation(type: .Length,
                location: Location(file: "filename", line: 1, character: 2),
                severity: .Warning,
                reason: "Violation Reason."),
            StyleViolation(type: .Length,
                location: Location(file: "filename", line: 1, character: 2),
                severity: .Error,
                reason: "Violation Reason.")
        ]
    }

    func testXcodeReporter() {
        XCTAssertEqual(
            XcodeReporter.generateReport(generateViolations()),
            "filename:1:2: warning: Length Violation: Violation Reason.\n" +
            "filename:1:2: error: Length Violation: Violation Reason."
        )
    }

    func testJSONReporter() {
        XCTAssertEqual(
            JSONReporter.generateReport(generateViolations()),
            "[\n" +
                "  {\n" +
                "    \"type\" : \"Length\",\n" +
                "    \"line\" : 1,\n" +
                "    \"reason\" : \"Violation Reason.\",\n" +
                "    \"file\" : \"filename\",\n" +
                "    \"character\" : 2,\n" +
                "    \"severity\" : \"Warning\"\n" +
                "  },\n" +
                "  {\n" +
                "    \"type\" : \"Length\",\n" +
                "    \"line\" : 1,\n" +
                "    \"reason\" : \"Violation Reason.\",\n" +
                "    \"file\" : \"filename\",\n" +
                "    \"character\" : 2,\n" +
                "    \"severity\" : \"Error\"\n" +
                "  }\n" +
            "]"
        )
    }

    func testCSVReporter() {
        XCTAssertEqual(
            CSVReporter.generateReport(generateViolations()),
            "file,line,character,severity,type,reason," +
            "filename,1,2,Warning,Length,Violation Reason.," +
            "filename,1,2,Error,Length,Violation Reason."
        )
    }
}
