import SwiftLintFramework
import XCTest

extension XCTestCase {
    func verifyRule(_ ruleDescription: RuleDescription,
                    ruleConfiguration: Any? = nil,
                    commentDoesntViolate: Bool = true,
                    stringDoesntViolate: Bool = true,
                    skipCommentTests: Bool = false,
                    skipStringTests: Bool = false,
                    skipDisableCommandTests: Bool = false,
                    testMultiByteOffsets: Bool = true,
                    testShebang: Bool = true,
                    file: StaticString = #file,
                    line: UInt = #line) {
        guard ruleDescription.minSwiftVersion <= .current else {
            return
        }

        guard let config = TestHelpers.makeConfig(
            ruleConfiguration,
            ruleDescription.identifier,
            skipDisableCommandTests: skipDisableCommandTests) else {
                XCTFail("Failed to create configuration", file: file, line: line)
                return
        }

        let disableCommands: [String]
        if skipDisableCommandTests {
            disableCommands = []
        } else {
            disableCommands = ruleDescription.allIdentifiers.map { "// swiftlint:disable \($0)\n" }
        }

        self.verifyLint(ruleDescription, config: config, commentDoesntViolate: commentDoesntViolate,
                        stringDoesntViolate: stringDoesntViolate, skipCommentTests: skipCommentTests,
                        skipStringTests: skipStringTests, disableCommands: disableCommands,
                        testMultiByteOffsets: testMultiByteOffsets, testShebang: testShebang)
        self.verifyCorrections(ruleDescription, config: config, disableCommands: disableCommands,
                               testMultiByteOffsets: testMultiByteOffsets)
    }

    func verifyLint(_ ruleDescription: RuleDescription,
                    config: Configuration,
                    commentDoesntViolate: Bool = true,
                    stringDoesntViolate: Bool = true,
                    skipCommentTests: Bool = false,
                    skipStringTests: Bool = false,
                    disableCommands: [String] = [],
                    testMultiByteOffsets: Bool = true,
                    testShebang: Bool = true,
                    file: StaticString = #file,
                    line: UInt = #line) {
        func verify(triggers: [Example], nonTriggers: [Example]) {
            verifyExamples(triggers: triggers, nonTriggers: nonTriggers, configuration: config,
                           requiresFileOnDisk: ruleDescription.requiresFileOnDisk,
                           file: file, line: line)
        }

        let triggers = ruleDescription.triggeringExamples
        let nonTriggers = ruleDescription.nonTriggeringExamples
        verify(triggers: triggers, nonTriggers: nonTriggers)

        if testMultiByteOffsets {
            verify(triggers: triggers.map { $0.addingEmoji }, nonTriggers: nonTriggers.map { $0.addingEmoji })
        }

        if testShebang {
            verify(triggers: triggers.map { $0.addingShebang }, nonTriggers: nonTriggers.map { $0.addingShebang })
        }

        func makeViolations(_ example: Example) -> [StyleViolation] {
            return TestHelpers.violations(example,
                                          config: config,
                                          requiresFileOnDisk: ruleDescription.requiresFileOnDisk)
        }

        // Comment doesn't violate
        if !skipCommentTests {
            XCTAssertEqual(
                triggers.flatMap({ makeViolations($0.with(code: "/*\n  " + $0.code + "\n */")) }).count,
                commentDoesntViolate ? 0 : triggers.count,
                file: file, line: line
            )
        }

        // String doesn't violate
        if !skipStringTests {
            XCTAssertEqual(
                triggers.flatMap({ makeViolations($0.with(code: $0.code.formattedAsStringLiteral)) }).count,
                stringDoesntViolate ? 0 : triggers.count,
                file: file, line: line
            )
        }

        // "disable" commands doesn't violate
        for command in disableCommands {
            XCTAssert(triggers.flatMap({ makeViolations($0.with(code: command + $0.code)) }).isEmpty,
                      file: file, line: line)
        }
    }

    func verifyCorrections(_ ruleDescription: RuleDescription, config: Configuration,
                           disableCommands: [String], testMultiByteOffsets: Bool) {
        // corrections
        ruleDescription.corrections.forEach {
            TestHelpers.testCorrection($0, configuration: config, testMultiByteOffsets: testMultiByteOffsets)
        }
        // make sure strings that don't trigger aren't corrected
        ruleDescription.nonTriggeringExamples.forEach {
            TestHelpers.testCorrection(($0, $0), configuration: config, testMultiByteOffsets: testMultiByteOffsets)
        }

        // "disable" commands do not correct
        ruleDescription.corrections.forEach { before, _ in
            for command in disableCommands {
                let beforeDisabled = command + before.code
                let expectedCleaned = before.with(
                    code: TestHelpers.cleanedContentsAndMarkerOffsets(from: beforeDisabled).0
                )
                config.assertCorrection(expectedCleaned, expected: expectedCleaned)
            }
        }
    }

    fileprivate func verifyNonTriggeringExamplesDoNotViolate(
        _ examples: [Example],
        config: Configuration,
        requiresFileOnDisk: Bool,
        file: StaticString = #file,
        line: UInt = #line) {
        for example in examples {
            let unexpectedViolations = TestHelpers.violations(example, config: config,
                                                              requiresFileOnDisk: requiresFileOnDisk)
            if unexpectedViolations.isEmpty { continue }
            let nonTriggerWithViolations = TestHelpers.render(violations: unexpectedViolations, in: example.code)
            XCTFail(
                "nonTriggeringExample violated: \n\(nonTriggerWithViolations)",
                file: example.file,
                line: example.line)
        }
    }

    fileprivate func verifyTriggeringExamplesViolate(
        _ examples: [Example],
        config: Configuration,
        requiresFileOnDisk: Bool,
        file callSiteFile: StaticString, line callSiteLine: UInt) {
        for example in examples {
            let triggerViolations = TestHelpers.violations(example, config: config,
                                                           requiresFileOnDisk: requiresFileOnDisk)

            // Triggering examples with violation markers violate at the marker's location
            let (cleanTrigger, markerOffsets) = TestHelpers.cleanedContentsAndMarkerOffsets(from: example.code)
            if markerOffsets.isEmpty {
                if triggerViolations.isEmpty {
                    XCTFail(
                        "triggeringExample did not violate: \n```\n\(example)\n```",
                        file: example.file,
                        line: example.line)
                }
                continue
            }
            let file = SwiftLintFile(contents: cleanTrigger)
            let expectedLocations = markerOffsets.map { Location(file: file, characterOffset: $0) }

            // Assert violations on unexpected location
            let violationsAtUnexpectedLocation = triggerViolations
                .filter { !expectedLocations.contains($0.location) }
            if !violationsAtUnexpectedLocation.isEmpty {
                XCTFail("triggeringExample violate at unexpected location: \n" +
                    "\(TestHelpers.render(violations: violationsAtUnexpectedLocation, in: example.code))",
                    file: example.file,
                    line: example.line)
            }

            // Assert locations missing violation
            let violatedLocations = triggerViolations.map { $0.location }
            let locationsWithoutViolation = expectedLocations
                .filter { !violatedLocations.contains($0) }
            if !locationsWithoutViolation.isEmpty {
                XCTFail("triggeringExample did not violate at expected location: \n" +
                    "\(TestHelpers.render(locations: locationsWithoutViolation, in: cleanTrigger))",
                    file: example.file,
                    line: example.line)
            }

            XCTAssertEqual(triggerViolations.count, expectedLocations.count,
                           file: example.file, line: example.line)
            for (triggerViolation, expectedLocation) in zip(triggerViolations, expectedLocations) {
                XCTAssertEqual(
                    triggerViolation.location, expectedLocation,
                    "'\(example)' violation didn't match expected location.",
                    file: example.file,
                    line: example.line)
            }
        }
    }

    private func verifyExamples(triggers: [Example], nonTriggers: [Example],
                                configuration config: Configuration, requiresFileOnDisk: Bool,
                                file callSiteFile: StaticString = #file,
                                line callSiteLine: UInt = #line) {
        verifyNonTriggeringExamplesDoNotViolate(nonTriggers,
                                                config: config,
                                                requiresFileOnDisk: requiresFileOnDisk,
                                                file: callSiteFile, line: callSiteLine)

        verifyTriggeringExamplesViolate(triggers,
                                        config: config,
                                        requiresFileOnDisk: requiresFileOnDisk,
                                        file: callSiteFile, line: callSiteLine)
    }

    // file and line parameters are first so we can use trailing closure syntax with the closure
    func checkError<T: Error & Equatable>(
        file: StaticString = #file,
        line: UInt = #line,
        _ error: T,
        closure: () throws -> Void) {
        do {
            try closure()
            XCTFail("No error caught", file: file, line: line)
        } catch let rError as T {
            if error != rError {
                XCTFail("Wrong error caught. Got \(rError) but was expecting \(error)", file: file, line: line)
            }
        } catch {
            XCTFail("Wrong error caught", file: file, line: line)
        }
    }
}
