//
//  TestHelpers.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SwiftLintFramework
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

private func violations(string: String, _ description: RuleDescription) -> [StyleViolation] {
    let disabledRules = allRuleIdentifiers.filter { $0 != description.identifier }
    let enabledRules = allRuleIdentifiers.filter { $0 == description.identifier }
    let config = Configuration(disabledRules: disabledRules, enabledRules: enabledRules)!
    return violations(string, config: config)
}

private func assertCorrection(before: String, expected: String) {
    guard let path = NSURL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        .URLByAppendingPathComponent(NSUUID().UUIDString + ".swift").path else {
        XCTFail("couldn't generate temporary path for assertCorrection()")
        return
    }
    if before.dataUsingEncoding(NSUTF8StringEncoding)?.writeToFile(path, atomically: true) != true {
        XCTFail("couldn't write to file for assertCorrection()")
        return
    }
    guard let file = File(path: path) else {
        XCTFail("couldn't read file at path '\(path)' for assertCorrection()")
        return
    }
    let corrections = Linter(file: file).correct()
    XCTAssertEqual(corrections.count, 1)
    XCTAssertEqual(file.contents, expected)
    do {
        let corrected = try NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding) as String
        XCTAssertEqual(corrected, expected)
    } catch {
        XCTFail("couldn't read file at path '\(path)': \(error)")
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
        let triggers = ruleDescription.triggeringExamples
        let nonTriggers = ruleDescription.nonTriggeringExamples

        // Non-triggering examples don't violate
        for nonTrigger in nonTriggers {
            XCTAssertTrue(violations(nonTrigger.string, ruleDescription).isEmpty,
                "Non triggering example violated.",
                file: nonTrigger.file, line: nonTrigger.line)
        }

        // Triggering examples violate
        for trigger in triggers {
            let string = trigger.string
            let triggerViolations = violations(string, ruleDescription)
            XCTAssertFalse(triggerViolations.isEmpty,
                "Triggering example did not violate.",
                file: trigger.file, line: trigger.line)
            // Triggering examples with violation markers violate at the marker's location
            let markerLocation = (string as NSString).rangeOfString(violationMarker).location
            if markerLocation == NSNotFound {
                continue
            }
            let cleanTrigger = string.stringByReplacingOccurrencesOfString(violationMarker,
                withString: "")
            XCTAssertEqual(triggerViolations.first!.location,
                Location(file: File(contents: cleanTrigger), characterOffset: markerLocation),
                "Location of violation was incorrect.",
                file: trigger.file, line: trigger.line)
        }

        // Comment doesn't violate
        XCTAssertEqual(
            triggers.flatMap({ violations("/*\n  " + $0.string + "\n */", ruleDescription) }).count,
            commentDoesntViolate ? 0 : triggers.count
        )

        // String doesn't violate
        XCTAssertEqual(
            triggers.flatMap({ violations($0.string.toStringLiteral(), ruleDescription) }).count,
            stringDoesntViolate ? 0 : triggers.count
        )

        // "disable" command doesn't violate
        let command = "// swiftlint:disable \(ruleDescription.identifier)\n"
        XCTAssert(triggers.flatMap({ violations(command + $0.string, ruleDescription) }).isEmpty)

        // corrections
        ruleDescription.corrections.forEach(assertCorrection)
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
