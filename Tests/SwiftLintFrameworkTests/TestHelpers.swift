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
        var content = contents[line - 1]
        let index = content.index(content.startIndex, offsetBy: character - 1)
        content.insert("↓", at: index)
        contents[line - 1] = content
    }
    return (["```"] + contents + ["```"]).joined(separator: "\n")
}

extension Configuration {
    fileprivate func assertCorrection(_ before: String,
                                      expected: String,
                                      file: StaticString = #file,
                                      line: UInt = #line) {
        guard let path = NSURL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent(NSUUID().uuidString + ".swift")?.path else {
                XCTFail("couldn't generate temporary path for assertCorrection()", file: file, line: line)
                return
        }
        let (cleanedBefore, markerOffsets) = cleanedContentsAndMarkerOffsets(from: before)
        do {
            try cleanedBefore.write(toFile: path, atomically: true, encoding: .utf8)
        } catch {
            XCTFail("couldn't write to file for assertCorrection() with error: \(error)", file: file, line: line)
            return
        }
        guard let incorrectFile = File(path: path) else {
            XCTFail("couldn't read file at path '\(path)' for assertCorrection()", file: file, line: line)
            return
        }
        // expectedLocations are needed to create before call `correct()`
        let expectedLocations = markerOffsets.map { Location(file: incorrectFile, characterOffset: $0) }
        let corrections = Linter(file: incorrectFile, configuration: self).correct().sorted {
            $0.location < $1.location
        }
        if expectedLocations.isEmpty {
            XCTAssertEqual(corrections.count, before != expected ? 1 : 0, file: file, line: line)
        } else {
            XCTAssertEqual(corrections.count, expectedLocations.count, file: file, line: line)
            for (correction, expectedLocation) in zip(corrections, expectedLocations) {
                XCTAssertEqual(correction.location, expectedLocation, file: file, line: line)
            }
        }
        XCTAssertEqual(incorrectFile.contents, expected, file: file, line: line)
        do {
            let corrected = try String(contentsOfFile: path, encoding: .utf8)
            XCTAssertEqual(corrected, expected, file: file, line: line)
        } catch {
            XCTFail("couldn't read file at path '\(path)': \(error)", file: file, line: line)
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

    // disabled on Linux because of https://bugs.swift.org/browse/SR-3448 and
    // https://bugs.swift.org/browse/SR-3449
    #if !os(Linux)
        if testMultiByteOffsets {
            config.assertCorrection(addEmoji(correction.0), expected: addEmoji(correction.1))
        }
    #endif
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
                    testMultiByteOffsets: Bool = true,
                    file: StaticString = #file,
                    line: UInt = #line) {
        guard let config = makeConfig(ruleConfiguration, ruleDescription.identifier) else {
            XCTFail(file: file, line: line)
            return
        }

        let triggers = ruleDescription.triggeringExamples
        let nonTriggers = ruleDescription.nonTriggeringExamples
        verifyExamples(triggers: triggers, nonTriggers: nonTriggers, configuration: config, file: file, line: line)

        // disabled on Linux because of https://bugs.swift.org/browse/SR-3448 and
        // https://bugs.swift.org/browse/SR-3449
        #if !os(Linux)
        if testMultiByteOffsets {
            verifyExamples(triggers: triggers.map(addEmoji),
                           nonTriggers: nonTriggers.map(addEmoji), configuration: config,
                           file: file, line: line)
        }
        #endif

        // Comment doesn't violate
        if !skipCommentTests {
            XCTAssertEqual(
                triggers.flatMap({ violations("/*\n  " + $0 + "\n */", config: config) }).count,
                commentDoesntViolate ? 0 : triggers.count,
                file: file,
                line: line
            )
        }

        // String doesn't violate
        if !skipStringTests {
            XCTAssertEqual(
                triggers.flatMap({ violations($0.toStringLiteral(), config: config) }).count,
                stringDoesntViolate ? 0 : triggers.count,
                file: file,
                line: line
            )
        }

        let disableCommands = ruleDescription.allIdentifiers.map { "// swiftlint:disable \($0)\n" }

        // "disable" commands doesn't violate
        for command in disableCommands {
            XCTAssert(triggers.flatMap({ violations(command + $0, config: config) }).isEmpty, file: file, line: line)
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
                                configuration config: Configuration,
                                file: StaticString = #file, line: UInt = #line) {
        // Non-triggering examples don't violate
        for nonTrigger in nonTriggers {
            let unexpectedViolations = violations(nonTrigger, config: config)
            if unexpectedViolations.isEmpty { continue }
            let nonTriggerWithViolations = render(violations: unexpectedViolations, in: nonTrigger)
            XCTFail("nonTriggeringExample violated: \n\(nonTriggerWithViolations)", file: file, line: line)
        }

        // Triggering examples violate
        for trigger in triggers {
            let triggerViolations = violations(trigger, config: config)

            // Triggering examples with violation markers violate at the marker's location
            let (cleanTrigger, markerOffsets) = cleanedContentsAndMarkerOffsets(from: trigger)
            if markerOffsets.isEmpty {
                if triggerViolations.isEmpty {
                    XCTFail("triggeringExample did not violate: \n```\n\(trigger)\n```", file: file, line: line)
                }
                continue
            }
            let violatingFile = File(contents: cleanTrigger)
            let expectedLocations = markerOffsets.map { Location(file: violatingFile, characterOffset: $0) }

            // Assert violations on unexpected location
            let violationsAtUnexpectedLocation = triggerViolations
                .filter { !expectedLocations.contains($0.location) }
            if !violationsAtUnexpectedLocation.isEmpty {
                XCTFail("triggeringExample violate at unexpected location: \n" +
                    "\(render(violations: violationsAtUnexpectedLocation, in: trigger))",
                    file: file,
                    line: line)
            }

            // Assert locations missing violation
            let violatedLocations = triggerViolations.map { $0.location }
            let locationsWithoutViolation = expectedLocations
                .filter { !violatedLocations.contains($0) }
            if !locationsWithoutViolation.isEmpty {
                XCTFail("triggeringExample did not violate at expected location: \n" +
                    "\(render(locations: locationsWithoutViolation, in: cleanTrigger))",
                    file: file,
                    line: line)
            }

            XCTAssertEqual(triggerViolations.count, expectedLocations.count, file: file, line: line)
            for (triggerViolation, expectedLocation) in zip(triggerViolations, expectedLocations) {
                XCTAssertEqual(triggerViolation.location, expectedLocation,
                               "'\(trigger)' violation didn't match expected location.",
                               file: file,
                               line: line)
            }
        }
    }

    func checkError<T: Error & Equatable>(
        _ error: T,
        file: StaticString = #file,
        line: UInt = #line,
        closure: () throws -> Void) {
        do {
            try closure()
            XCTFail("No error caught", file: file, line: line)
        } catch let rError as T {
            if error != rError {
                XCTFail("Wrong error caught", file: file, line: line)
            }
        } catch {
            XCTFail("Wrong error caught", file: file, line: line)
        }
    }
}
