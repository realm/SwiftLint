//
//  WarningThresholdTests.swift
//  SwiftLint
//
//  Created by George Woodham on 7/07/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import XCTest
import SourceKittenFramework
@testable import SwiftLintFramework

class WarningThresholdTests: XCTestCase {

    func generateViolations() -> [StyleViolation] {
        let location = Location(file: "filename", line: 1, character: 2)
        return [
            StyleViolation(ruleDescription: LineLengthRule.description,
                severity: .Warning,
                location: location,
                reason: "Violation Reason.1"),
            StyleViolation(ruleDescription: LineLengthRule.description,
                severity: .Warning,
                location: location,
                reason: "Violation Reason.2")
        ]
    }

    func testWarningThresholdChangedThreshold() {
        let violations = generateViolations()
        do {
            let warningThreshold = try WarningThresholdRule(configuration: ["warning": 1])
            XCTAssertEqual(warningThreshold.validate(violations).count, 3)
        } catch {
            XCTFail()
        }
    }

    func testWarningThresholdNoViolations() {
        let violations: [StyleViolation] = []
        do {
            let warningThreshold = try WarningThresholdRule(configuration: ["warning": 1])
            XCTAssertEqual(warningThreshold.validate(violations).count, 0)
        } catch {
            XCTFail()
        }
    }

    func testWarningThresholdDefaultThreshold() {
        let violations = generateViolations()
        let warningThreshold = WarningThresholdRule()
        XCTAssertEqual(warningThreshold.validate(violations).count, 2)
    }

    func testWarningThresholdChangedErrorThreshold() {
        let violations = generateViolations()
        do {
            let warningThreshold = try WarningThresholdRule(configuration: ["error": 1])
            XCTAssertEqual(warningThreshold.validate(violations).count, 2)
        } catch {
            XCTFail()
        }
    }

    func testWarningThresholdChangedErrorThresholdToBeHigherThanWarning() {
        let violations = generateViolations()
        do {
            // swiftlint:disable line_length
            let warningThreshold = try WarningThresholdRule(configuration: ["warning":1, "error": 2])
            // swiftlint:enable line_length
            XCTAssertEqual(warningThreshold.validate(violations).count, 3)
        } catch {
            XCTFail()
        }
    }

}
