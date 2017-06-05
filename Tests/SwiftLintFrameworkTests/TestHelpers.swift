//
//  TestHelpers.swift
//  SwiftLint
//
//  Created by JP Simard on 5/16/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework
@testable import SwiftLintFramework
import XCTest

private let violationMarker = "↓"

let allRuleIdentifiers = Array(masterRuleList.list.keys)

func violations(_ string: String, config: Configuration = Configuration()) -> [StyleViolation] {
    File.clearCaches()
    let stringStrippingMarkers = string.replacingOccurrences(of: violationMarker, with: "")
    let file = File(contents: stringStrippingMarkers)
    return Linter(file: file, configuration: config).styleViolations
}

private func cleanedContentsAndMarkerOffsets(from contents: String) -> (String, [Int]) {
    var contents = contents.bridge()
    var markerOffsets = [Int]()
    var markerRange = contents.range(of: violationMarker)
    while markerRange.location != NSNotFound {
        markerOffsets.append(markerRange.location)
        contents = contents.replacingCharacters(in: markerRange, with: "").bridge()
        markerRange = contents.range(of: violationMarker)
    }
    return (contents.bridge(), markerOffsets.sorted())
}

private func render(violations: [StyleViolation], in contents: String) -> String {
    var contents = contents.bridge().lines().map { $0.content }
    for violation in violations.sorted(by: { $0.location > $1.location }) {
        guard let line = violation.location.line,
            let character = violation.location.character else { continue }

        let message = String(repeating: " ", count: character - 1) + "^ " + [
            "\(violation.severity.rawValue): ",
            "\(violation.ruleDescription.name) Violation: ",
            violation.reason,
            " (\(violation.ruleDescription.identifier))"].joined()
        if line >= contents.count {
            contents.append(message)
        } else {
            contents.insert(message, at: line)
        }
    }
    return (["```"] + contents + ["```"]).joined(separator: "\n")
}

private func render(locations: [Location], in contents: String) -> String {
    var contents = contents.bridge().lines().map { $0.content }
    for location in locations.sorted(by: > ) {
        guard let line = location.line, let character = location.character else { continue }
        let content = NSMutableString(string: contents[line - 1])
        content.insert("↓", at: character - 1)
        contents[line - 1] = content.bridge()
    }
    return (["```"] + contents + ["```"]).joined(separator: "\n")
}

extension Configuration {
    fileprivate func assertCorrection(_ before: String, expected: String) {
        guard let path = NSURL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent(NSUUID().uuidString + ".swift")?.path else {
                XCTFail("couldn't generate temporary path for assertCorrection()")
                return
        }
        let (cleanedBefore, markerOffsets) = cleanedContentsAndMarkerOffsets(from: before)
        do {
            try cleanedBefore.write(toFile: path, atomically: true, encoding: .utf8)
        } catch {
            XCTFail("couldn't write to file for assertCorrection() with error: \(error)")
            return
        }
        guard let file = File(path: path) else {
            XCTFail("couldn't read file at path '\(path)' for assertCorrection()")
            return
        }
        // expectedLocations are needed to create before call `correct()`
        let expectedLocations = markerOffsets.map { Location(file: file, characterOffset: $0) }
        let corrections = Linter(file: file, configuration: self).correct().sorted {
            $0.location < $1.location
        }
        if expectedLocations.isEmpty {
            XCTAssertEqual(corrections.count, before != expected ? 1 : 0)
        } else {
            XCTAssertEqual(corrections.count, expectedLocations.count)
            for (correction, expectedLocation) in zip(corrections, expectedLocations) {
                XCTAssertEqual(correction.location, expectedLocation)
            }
        }
        XCTAssertEqual(file.contents, expected)
        do {
            let corrected = try String(contentsOfFile: path, encoding: .utf8)
            XCTAssertEqual(corrected, expected)
        } catch {
            XCTFail("couldn't read file at path '\(path)': \(error)")
        }
    }
}

extension String {
    fileprivate func toStringLiteral() -> String {
        return "\"" + replacingOccurrences(of: "\n", with: "\\n") + "\""
    }
}

internal func makeConfig(_ ruleConfiguration: Any?, _ identifier: String) -> Configuration? {
    if let ruleConfiguration = ruleConfiguration, let ruleType = masterRuleList.list[identifier] {
        // The caller has provided a custom configuration for the rule under test
        return (try? ruleType.init(configuration: ruleConfiguration)).flatMap { configuredRule in
            return Configuration(whitelistRules: [identifier], configuredRules: [configuredRule])
        }
    }
    return Configuration(whitelistRules: [identifier])
}

private func testCorrection(_ correction: (String, String),
                            configuration config: Configuration,
                            testMultiByteOffsets: Bool) {
    config.assertCorrection(correction.0, expected: correction.1)
    if testMultiByteOffsets {
        config.assertCorrection(addEmoji(correction.0), expected: addEmoji(correction.1))
    }
}

private func addEmoji(_ string: String) -> String {
    return "/* 👨‍👩‍👧‍👦👨‍👩‍👧‍👦👨‍👩‍👧‍👦 */\n\(string)"
}

extension XCTestCase {
    // swiftlint:disable:next function_body_length
    func verifyRule(_ ruleDescription: RuleDescription,
                    ruleConfiguration: Any? = nil,
                    commentDoesntViolate: Bool = true,
                    stringDoesntViolate: Bool = true,
                    skipCommentTests: Bool = false,
                    skipStringTests: Bool = false,
                    testMultiByteOffsets: Bool = true) {
        guard let config = makeConfig(ruleConfiguration, ruleDescription.identifier) else {
            XCTFail()
            return
        }

        let triggers = ruleDescription.triggeringExamples
        let nonTriggers = ruleDescription.nonTriggeringExamples
        verifyExamples(triggers: triggers, nonTriggers: nonTriggers, configuration: config)

        if testMultiByteOffsets {
            verifyExamples(triggers: triggers.map(addEmoji),
                           nonTriggers: nonTriggers.map(addEmoji), configuration: config)
        }

        // Comment doesn't violate
        if !skipCommentTests {
            XCTAssertEqual(
                triggers.flatMap({ violations("/*\n  " + $0 + "\n */", config: config) }).count,
                commentDoesntViolate ? 0 : triggers.count
            )
        }

        // String doesn't violate
        if !skipStringTests {
            XCTAssertEqual(
                triggers.flatMap({ violations($0.toStringLiteral(), config: config) }).count,
                stringDoesntViolate ? 0 : triggers.count
            )
        }

        let disableCommands = ruleDescription.allIdentifiers.map { "// swiftlint:disable \($0)\n" }

        // "disable" commands doesn't violate
        for command in disableCommands {
            XCTAssert(triggers.flatMap({ violations(command + $0, config: config) }).isEmpty)
        }

        // corrections
        ruleDescription.corrections.forEach {
            testCorrection($0, configuration: config, testMultiByteOffsets: testMultiByteOffsets)
        }
        // make sure strings that don't trigger aren't corrected
        zip(nonTriggers, nonTriggers).forEach {
            testCorrection($0, configuration: config, testMultiByteOffsets: testMultiByteOffsets)
        }

        // "disable" commands do not correct
        ruleDescription.corrections.forEach { before, _ in
            for command in disableCommands {
                let beforeDisabled = command + before
                let expectedCleaned = cleanedContentsAndMarkerOffsets(from: beforeDisabled).0
                config.assertCorrection(expectedCleaned, expected: expectedCleaned)
            }
        }

    }

    private func verifyExamples(triggers: [String], nonTriggers: [String],
                                configuration config: Configuration) {
        // Non-triggering examples don't violate
        for nonTrigger in nonTriggers {
            let unexpectedViolations = violations(nonTrigger, config: config)
            if unexpectedViolations.isEmpty { continue }
            let nonTriggerWithViolations = render(violations: unexpectedViolations, in: nonTrigger)
            XCTFail("nonTriggeringExample violated: \n\(nonTriggerWithViolations)")
        }

        // Triggering examples violate
        for trigger in triggers {
            let triggerViolations = violations(trigger, config: config)

            // Triggering examples with violation markers violate at the marker's location
            let (cleanTrigger, markerOffsets) = cleanedContentsAndMarkerOffsets(from: trigger)
            if markerOffsets.isEmpty {
                if triggerViolations.isEmpty {
                    XCTFail("triggeringExample did not violate: \n```\n\(trigger)\n```")
                }
                continue
            }
            let file = File(contents: cleanTrigger)
            let expectedLocations = markerOffsets.map { Location(file: file, characterOffset: $0) }

            // Assert violations on unexpected location
            let violationsAtUnexpectedLocation = triggerViolations
                .filter { !expectedLocations.contains($0.location) }
            if !violationsAtUnexpectedLocation.isEmpty {
                XCTFail("triggeringExample violate at unexpected location: \n" +
                    "\(render(violations: violationsAtUnexpectedLocation, in: trigger))")
            }

            // Assert locations missing violation
            let violatedLocations = triggerViolations.map { $0.location }
            let locationsWithoutViolation = expectedLocations
                .filter { !violatedLocations.contains($0) }
            if !locationsWithoutViolation.isEmpty {
                XCTFail("triggeringExample did not violate at expected location: \n" +
                    "\(render(locations: locationsWithoutViolation, in: cleanTrigger))")
            }

            XCTAssertEqual(triggerViolations.count, expectedLocations.count)
            for (triggerViolation, expectedLocation) in zip(triggerViolations, expectedLocations) {
                XCTAssertEqual(triggerViolation.location, expectedLocation,
                               "'\(trigger)' violation didn't match expected location.")
            }
        }
    }

    func checkError<T: Error & Equatable>(_ error: T, closure: () throws -> Void) {
        do {
            try closure()
            XCTFail("No error caught")
        } catch let rError as T {
            if error != rError {
                XCTFail("Wrong error caught. Got \(rError) but was expecting \(error)")
            }
        } catch {
            XCTFail("Wrong error caught")
        }
    }
}
