//
//  TestHelpers.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Foundation
@testable import SwiftLintFramework
import SourceKittenFramework
import XCTest

private let violationMarker = "↓"

let allRuleIdentifiers = Array(masterRuleList.list.keys)

func violations(string: String, config: Configuration = Configuration()) -> [StyleViolation] {
    File.clearCaches()
    let stringStrippingMarkers = string.stringByReplacingOccurrencesOfString(violationMarker,
        withString: "")
    let file = File(contents: stringStrippingMarkers)
    return Linter(file: file, configuration: config).styleViolations
}

extension Configuration {
    private func assertCorrection(before: String, expected: String) {
        guard let path = NSURL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .URLByAppendingPathComponent(NSUUID().UUIDString + ".swift").path else {
                XCTFail("couldn't generate temporary path for assertCorrection()")
                return
        }
        if before.dataUsingEncoding(NSUTF8StringEncoding)?
            .writeToFile(path, atomically: true) != true {
                XCTFail("couldn't write to file for assertCorrection()")
                return
        }
        guard let file = File(path: path) else {
            XCTFail("couldn't read file at path '\(path)' for assertCorrection()")
            return
        }
        let corrections = Linter(file: file, configuration: self).correct()
        XCTAssertEqual(corrections.count, Int(before != expected))
        XCTAssertEqual(file.contents, expected)
        do {
            let corrected = try NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding)
            XCTAssertEqual(corrected as String, expected)
        } catch {
            XCTFail("couldn't read file at path '\(path)': \(error)")
        }
    }
}

extension String {
    private func toStringLiteral() -> String {
        return "\"" + stringByReplacingOccurrencesOfString("\n", withString: "\\n") + "\""
    }
}

extension XCTestCase {
    func verifyRule(ruleDescription: RuleDescription, commentDoesntViolate: Bool = true,
                    stringDoesntViolate: Bool = true) {
        let config = Configuration(whitelistRules: [ruleDescription.identifier])!
        let triggers = ruleDescription.triggeringExamples
        let nonTriggers = ruleDescription.nonTriggeringExamples

        // Non-triggering examples don't violate
        XCTAssertEqual(nonTriggers.flatMap({ violations($0, config: config) }), [])

        var violationsCount = 0
        for trigger in triggers {
            let triggerViolations = violations(trigger, config: config)
            violationsCount += triggerViolations.count
            // Triggering examples with violation markers violate at the marker's location
            let markerLocation = (trigger as NSString).rangeOfString(violationMarker).location
            if markerLocation == NSNotFound { continue }
            let cleanTrigger = trigger.stringByReplacingOccurrencesOfString(violationMarker,
                withString: "")
            XCTAssertEqual(triggerViolations.first?.location,
                Location(file: File(contents: cleanTrigger), characterOffset: markerLocation))
        }
        // Triggering examples violate
        XCTAssertEqual(violationsCount, triggers.count)

        // Comment doesn't violate
        XCTAssertEqual(
            triggers.flatMap({ violations("/*\n  " + $0 + "\n */", config: config) }).count,
            commentDoesntViolate ? 0 : triggers.count
        )

        // String doesn't violate
        XCTAssertEqual(
            triggers.flatMap({ violations($0.toStringLiteral(), config: config) }).count,
            stringDoesntViolate ? 0 : triggers.count
        )

        // "disable" command doesn't violate
        let command = "// swiftlint:disable \(ruleDescription.identifier)\n"
        XCTAssert(triggers.flatMap({ violations(command + $0, config: config) }).isEmpty)

        // corrections
        ruleDescription.corrections.forEach(config.assertCorrection)
        // make sure strings that don't trigger aren't corrected
        zip(nonTriggers, nonTriggers).forEach(config.assertCorrection)
    }

    func checkError<T: protocol<ErrorType, Equatable>>(error: T, closure: () throws -> () ) {
        do {
            try closure()
            XCTFail("No error caught")
        } catch let rError as T {
            if error != rError {
                XCTFail("Wrong error caught")
            }
        } catch {
            XCTFail("Wrong error caught")
        }
    }
}
