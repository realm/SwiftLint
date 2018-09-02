import Foundation
import SourceKittenFramework
@testable import SwiftLintFramework
import XCTest

private let violationMarker = "↓"

private extension File {
    static func temporary(withContents contents: String) -> File {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("swift")
        _ = try? contents.data(using: .utf8)!.write(to: url)
        return File(path: url.path)!
    }

    func makeCompilerArguments() -> [String] {
        return ["-sdk", sdkPath(), "-j4", path!]
    }
}

extension String {
    func stringByAppendingPathComponent(_ pathComponent: String) -> String {
        return bridge().appendingPathComponent(pathComponent)
    }
}

let allRuleIdentifiers = Array(masterRuleList.list.keys)

func violations(_ string: String, config: Configuration = Configuration()!,
                requiresFileOnDisk: Bool = false) -> [StyleViolation] {
    File.clearCaches()
    let stringStrippingMarkers = string.replacingOccurrences(of: violationMarker, with: "")
    guard requiresFileOnDisk else {
        let file = File(contents: stringStrippingMarkers)
        let linter = Linter(file: file, configuration: config)
        return linter.styleViolations
    }

    let file = File.temporary(withContents: stringStrippingMarkers)
    let linter = Linter(file: file, configuration: config, compilerArguments: file.makeCompilerArguments())
    return linter.styleViolations.map { violation in
        let locationWithoutFile = Location(file: nil, line: violation.location.line,
                                           character: violation.location.character)
        return StyleViolation(ruleDescription: violation.ruleDescription, severity: violation.severity,
                              location: locationWithoutFile, reason: violation.reason)
    }
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

private extension Configuration {
    func assertCorrection(_ before: String, expected: String) {
        let (cleanedBefore, markerOffsets) = cleanedContentsAndMarkerOffsets(from: before)
        let file = File.temporary(withContents: cleanedBefore)
        // expectedLocations are needed to create before call `correct()`
        let expectedLocations = markerOffsets.map { Location(file: file, characterOffset: $0) }
        let includeCompilerArguments = self.rules.contains(where: { $0 is AnalyzerRule })
        let compilerArguments = includeCompilerArguments ? file.makeCompilerArguments() : []
        let linter = Linter(file: file, configuration: self, compilerArguments: compilerArguments)
        let corrections = linter.correct().sorted { $0.location < $1.location }
        if expectedLocations.isEmpty {
            XCTAssertEqual(corrections.count, before != expected ? 1 : 0)
        } else {
            XCTAssertEqual(corrections.count, expectedLocations.count)
            for (correction, expectedLocation) in zip(corrections, expectedLocations) {
                XCTAssertEqual(correction.location, expectedLocation)
            }
        }
        XCTAssertEqual(file.contents, expected)
        let path = file.path!
        do {
            let corrected = try String(contentsOfFile: path, encoding: .utf8)
            XCTAssertEqual(corrected, expected)
        } catch {
            XCTFail("couldn't read file at path '\(path)': \(error)")
        }
    }
}

private extension String {
    func toStringLiteral() -> String {
        return "\"" + replacingOccurrences(of: "\n", with: "\\n") + "\""
    }
}

internal func makeConfig(_ ruleConfiguration: Any?, _ identifier: String,
                         skipDisableCommandTests: Bool = false) -> Configuration? {
    let superfluousDisableCommandRuleIdentifier = SuperfluousDisableCommandRule.description.identifier
    let identifiers = skipDisableCommandTests ? [identifier] : [identifier, superfluousDisableCommandRuleIdentifier]

    if let ruleConfiguration = ruleConfiguration, let ruleType = masterRuleList.list[identifier] {
        // The caller has provided a custom configuration for the rule under test
        return (try? ruleType.init(configuration: ruleConfiguration)).flatMap { configuredRule in
            let rules = skipDisableCommandTests ? [configuredRule] : [configuredRule, SuperfluousDisableCommandRule()]
            return Configuration(rulesMode: .whitelisted(identifiers), configuredRules: rules)
        }
    }
    return Configuration(rulesMode: .whitelisted(identifiers))
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

private func addShebang(_ string: String) -> String {
    return "#!/usr/bin/env swift\n\(string)"
}

extension XCTestCase {
    func verifyRule(_ ruleDescription: RuleDescription,
                    ruleConfiguration: Any? = nil,
                    commentDoesntViolate: Bool = true,
                    stringDoesntViolate: Bool = true,
                    skipCommentTests: Bool = false,
                    skipStringTests: Bool = false,
                    skipDisableCommandTests: Bool = false,
                    testMultiByteOffsets: Bool = true,
                    testShebang: Bool = true) {
        guard ruleDescription.minSwiftVersion <= .current else {
            return
        }

        guard let config = makeConfig(ruleConfiguration,
                                      ruleDescription.identifier,
                                      skipDisableCommandTests: skipDisableCommandTests) else {
            XCTFail("Failed to create configuration")
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
                    testShebang: Bool = true) {
        func verify(triggers: [String], nonTriggers: [String]) {
            verifyExamples(triggers: triggers, nonTriggers: nonTriggers, configuration: config,
                           requiresFileOnDisk: ruleDescription.requiresFileOnDisk)
        }

        let triggers = ruleDescription.triggeringExamples
        let nonTriggers = ruleDescription.nonTriggeringExamples
        verify(triggers: triggers, nonTriggers: nonTriggers)

        if testMultiByteOffsets {
            verify(triggers: triggers.map(addEmoji), nonTriggers: nonTriggers.map(addEmoji))
        }

        if testShebang {
            verify(triggers: triggers.map(addShebang), nonTriggers: nonTriggers.map(addShebang))
        }

        func makeViolations(_ string: String) -> [StyleViolation] {
            return violations(string, config: config, requiresFileOnDisk: ruleDescription.requiresFileOnDisk)
        }

        // Comment doesn't violate
        if !skipCommentTests {
            XCTAssertEqual(
                triggers.flatMap({ makeViolations("/*\n  " + $0 + "\n */") }).count,
                commentDoesntViolate ? 0 : triggers.count
            )
        }

        // String doesn't violate
        if !skipStringTests {
            XCTAssertEqual(
                triggers.flatMap({ makeViolations($0.toStringLiteral()) }).count,
                stringDoesntViolate ? 0 : triggers.count
            )
        }

        // "disable" commands doesn't violate
        for command in disableCommands {
            XCTAssert(triggers.flatMap({ makeViolations(command + $0) }).isEmpty)
        }
    }

    func verifyCorrections(_ ruleDescription: RuleDescription, config: Configuration,
                           disableCommands: [String], testMultiByteOffsets: Bool) {
        // corrections
        ruleDescription.corrections.forEach {
            testCorrection($0, configuration: config, testMultiByteOffsets: testMultiByteOffsets)
        }
        // make sure strings that don't trigger aren't corrected
        ruleDescription.nonTriggeringExamples.forEach {
            testCorrection(($0, $0), configuration: config, testMultiByteOffsets: testMultiByteOffsets)
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
                                configuration config: Configuration, requiresFileOnDisk: Bool) {
        // Non-triggering examples don't violate
        for nonTrigger in nonTriggers {
            let unexpectedViolations = violations(nonTrigger, config: config,
                                                  requiresFileOnDisk: requiresFileOnDisk)
            if unexpectedViolations.isEmpty { continue }
            let nonTriggerWithViolations = render(violations: unexpectedViolations, in: nonTrigger)
            XCTFail("nonTriggeringExample violated: \n\(nonTriggerWithViolations)")
        }

        // Triggering examples violate
        for trigger in triggers {
            let triggerViolations = violations(trigger, config: config,
                                               requiresFileOnDisk: requiresFileOnDisk)

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
