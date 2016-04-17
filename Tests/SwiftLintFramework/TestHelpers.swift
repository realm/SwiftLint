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

func cleanedContentsAndMarkerOffsets(from contents: String) -> (String, [Int]) {
    var contents = contents as NSString
    var markerOffsets = [Int]()
    var markerRange = contents.rangeOfString(violationMarker)
    while markerRange.location != NSNotFound {
        markerOffsets.append(markerRange.location)
        contents = contents.stringByReplacingCharactersInRange(markerRange, withString: "")
        markerRange = contents.rangeOfString(violationMarker)
    }
    return (contents as String, markerOffsets.sort())
}

extension Configuration {
    private func assertCorrection(before: String, expected: String) {
        guard let path = NSURL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .URLByAppendingPathComponent(NSUUID().UUIDString + ".swift").path else {
                XCTFail("couldn't generate temporary path for assertCorrection()")
                return
        }
        let (cleanedBefore, markerOffsets) = cleanedContentsAndMarkerOffsets(from: before)
        if cleanedBefore.dataUsingEncoding(NSUTF8StringEncoding)?
            .writeToFile(path, atomically: true) != true {
                XCTFail("couldn't write to file for assertCorrection()")
                return
        }
        guard let file = File(path: path) else {
            XCTFail("couldn't read file at path '\(path)' for assertCorrection()")
            return
        }
        // expectedLocations are needed to create before call `correct()`
        let expectedLocations = markerOffsets.map { Location(file: file, characterOffset: $0) }
        let corrections = Linter(file: file, configuration: self).correct().sort {
            $0.location < $1.location
        }
        if expectedLocations.isEmpty {
            XCTAssertEqual(corrections.count, Int(before != expected))
        } else {
            XCTAssertEqual(corrections.count, expectedLocations.count)
            for (correction, expectedLocation) in zip(corrections, expectedLocations) {
                XCTAssertEqual(correction.location, expectedLocation)
            }
        }
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
        var expectedViolationsCount = 0
        for trigger in triggers {
            let triggerViolations = violations(trigger, config: config).sort {
                $0.location < $1.location
            }
            violationsCount += triggerViolations.count
            // Triggering examples with violation markers violate at the marker's location
            let (cleanTrigger, markerOffsets) = cleanedContentsAndMarkerOffsets(from: trigger)
            if markerOffsets.isEmpty {
                expectedViolationsCount += 1
                continue
            }
            expectedViolationsCount += markerOffsets.count
            let file = File(contents: cleanTrigger)
            let expectedLocations = markerOffsets.map { Location(file: file, characterOffset: $0) }
            XCTAssertEqual(triggerViolations.count, expectedLocations.count)
            for (triggerViolation, expectedLocation) in zip(triggerViolations, expectedLocations) {
                XCTAssertEqual(triggerViolation.location, expectedLocation)
            }
        }
        // Triggering examples violate
        XCTAssertEqual(violationsCount, expectedViolationsCount)

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
