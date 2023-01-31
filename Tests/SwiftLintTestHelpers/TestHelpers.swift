import Foundation
import SourceKittenFramework
@_spi(TestHelper)
import SwiftLintFramework
import XCTest

// swiftlint:disable file_length

private let violationMarker = "↓"

private extension SwiftLintFile {
    static func testFile(withContents contents: String, persistToDisk: Bool = false) -> SwiftLintFile {
        let file: SwiftLintFile
        if persistToDisk {
            let url = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("swift")
            _ = try? contents.data(using: .utf8)!.write(to: url)
            file = SwiftLintFile(path: url.path)!
        } else {
            file = SwiftLintFile(contents: contents)
        }

        file.markAsTestFile()
        return file
    }

    func makeCompilerArguments() -> [String] {
        let sdk = sdkPath()
        let frameworks = URL(fileURLWithPath: sdk, isDirectory: true)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Library")
            .appendingPathComponent("Frameworks")
            .path
        return [
            "-F",
            frameworks,
            "-sdk", sdk,
            "-j4", path!
        ]
    }
}

public extension String {
    func stringByAppendingPathComponent(_ pathComponent: String) -> String {
        return bridge().appendingPathComponent(pathComponent)
    }
}

public let allRuleIdentifiers = Set(primaryRuleList.list.keys)

public extension Configuration {
    func applyingConfiguration(from example: Example) -> Configuration {
        guard let exampleConfiguration = example.configuration,
           case let .only(onlyRules) = self.rulesMode,
           let firstRule = (onlyRules.first { $0 != "superfluous_disable_command" }),
           case let configDict = ["only_rules": onlyRules, firstRule: exampleConfiguration],
           let typedConfiguration = try? Configuration(dict: configDict) else { return self }
        return merged(withChild: typedConfiguration, rootDirectory: rootDirectory)
    }
}

public func violations(_ example: Example, config inputConfig: Configuration = Configuration.default,
                       requiresFileOnDisk: Bool = false) -> [StyleViolation] {
    SwiftLintFile.clearCaches()
    let config = inputConfig.applyingConfiguration(from: example)
    let stringStrippingMarkers = example.removingViolationMarkers()
    guard requiresFileOnDisk else {
        let file = SwiftLintFile.testFile(withContents: stringStrippingMarkers.code)
        let storage = RuleStorage()
        let linter = Linter(file: file, configuration: config).collect(into: storage)
        return linter.styleViolations(using: storage)
    }

    let file = SwiftLintFile.testFile(withContents: stringStrippingMarkers.code, persistToDisk: true)
    let storage = RuleStorage()
    let collecter = Linter(file: file, configuration: config, compilerArguments: file.makeCompilerArguments())
    let linter = collecter.collect(into: storage)
    return linter.styleViolations(using: storage).withoutFiles()
}

public extension Collection where Element == String {
    func violations(config: Configuration = Configuration.default, requiresFileOnDisk: Bool = false)
        -> [StyleViolation] {
            return map { SwiftLintFile.testFile(withContents: $0, persistToDisk: requiresFileOnDisk) }
                .violations(config: config, requiresFileOnDisk: requiresFileOnDisk)
    }

    @_spi(TestHelper)
    func corrections(config: Configuration = Configuration.default, requiresFileOnDisk: Bool = false) -> [Correction] {
        return map { SwiftLintFile.testFile(withContents: $0, persistToDisk: requiresFileOnDisk) }
            .corrections(config: config, requiresFileOnDisk: requiresFileOnDisk)
    }
}

public extension Collection where Element: SwiftLintFile {
    func violations(config: Configuration = Configuration.default, requiresFileOnDisk: Bool = false)
        -> [StyleViolation] {
            let storage = RuleStorage()
            let violations = map({ file in
                Linter(file: file, configuration: config,
                       compilerArguments: requiresFileOnDisk ? file.makeCompilerArguments() : [])
            }).map({ linter in
                linter.collect(into: storage)
            }).flatMap({ linter in
                linter.styleViolations(using: storage)
            })
            return requiresFileOnDisk ? violations.withoutFiles() : violations
    }

    @_spi(TestHelper)
    func corrections(config: Configuration = Configuration.default, requiresFileOnDisk: Bool = false) -> [Correction] {
        let storage = RuleStorage()
        let corrections = map({ file in
            Linter(file: file, configuration: config,
                   compilerArguments: requiresFileOnDisk ? file.makeCompilerArguments() : [])
        }).map({ linter in
            linter.collect(into: storage)
        }).flatMap({ linter in
            linter.correct(using: storage)
        })
        return requiresFileOnDisk ? corrections.withoutFiles() : corrections
    }
}

private extension Collection where Element == StyleViolation {
    func withoutFiles() -> [StyleViolation] {
        return map { violation in
            let locationWithoutFile = Location(file: nil, line: violation.location.line,
                                               character: violation.location.character)
            return violation.with(location: locationWithoutFile)
        }
    }
}

private extension Collection where Element == Correction {
    func withoutFiles() -> [Correction] {
        return map { correction in
            let locationWithoutFile = Location(file: nil, line: correction.location.line,
                                               character: correction.location.character)
            return Correction(ruleDescription: correction.ruleDescription, location: locationWithoutFile)
        }
    }
}

public extension Collection where Element == Example {
    /// Returns a dictionary with SwiftLint violation markers (↓) removed from keys.
    ///
    /// - returns: A new `Array`.
    func removingViolationMarkers() -> [Element] {
        return map { $0.removingViolationMarkers() }
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
    var contents = StringView(contents).lines.map { $0.content }
    for violation in violations.sorted(by: { $0.location > $1.location }) {
        guard let line = violation.location.line,
            let character = violation.location.character else { continue }

        let message = String(repeating: " ", count: character - 1) + "^ " + [
            "\(violation.severity.rawValue): ",
            "\(violation.ruleName) Violation: ",
            violation.reason,
            " (\(violation.ruleIdentifier))"].joined()
        if line >= contents.count {
            contents.append(message)
        } else {
            contents.insert(message, at: line)
        }
    }
    return """
        ```
        \(contents.joined(separator: "\n"))
        ```
        """
}

private func render(locations: [Location], in contents: String) -> String {
    var contents = StringView(contents).lines.map { $0.content }
    for location in locations.sorted(by: > ) {
        guard let line = location.line, let character = location.character else { continue }
        let content = NSMutableString(string: contents[line - 1])
        content.insert("↓", at: character - 1)
        contents[line - 1] = content.bridge()
    }
    return """
        ```
        \(contents.joined(separator: "\n"))
        ```
        """
}

private extension Configuration {
    func assertCorrection(_ before: Example, expected: Example) {
        let (cleanedBefore, markerOffsets) = cleanedContentsAndMarkerOffsets(from: before.code)
        let file = SwiftLintFile.testFile(withContents: cleanedBefore, persistToDisk: true)
        // expectedLocations are needed to create before call `correct()`
        let expectedLocations = markerOffsets.map { Location(file: file, characterOffset: $0) }
        let includeCompilerArguments = self.rules.contains(where: { $0 is AnalyzerRule })
        let compilerArguments = includeCompilerArguments ? file.makeCompilerArguments() : []
        let storage = RuleStorage()
        let collecter = Linter(file: file, configuration: self, compilerArguments: compilerArguments)
        let linter = collecter.collect(into: storage)
        let corrections = linter.correct(using: storage).sorted { $0.location < $1.location }
        if expectedLocations.isEmpty {
            XCTAssertEqual(
                corrections.count, before.code != expected.code ? 1 : 0, #function + ".expectedLocationsEmpty",
                file: before.file, line: before.line)
        } else {
            XCTAssertEqual(
                corrections.count,
                expectedLocations.count,
                #function + ".expected locations: \(expectedLocations.count)",
                file: before.file, line: before.line
            )
            // With SwiftSyntax rewriters, the visitors get called with the new nodes after previous mutations have
            // been applied, so it's not straightforward to translate those back into the original source positions.
            // So only check the first locations
            if let firstCorrection = corrections.first {
                XCTAssertEqual(
                    firstCorrection.location,
                    expectedLocations.first,
                    #function + ".correction location",
                    file: before.file, line: before.line
                )
            }
        }
        XCTAssertEqual(
            file.contents,
            expected.code,
            #function + ".file contents",
            file: before.file, line: before.line)
        let path = file.path!
        do {
            let corrected = try String(contentsOfFile: path, encoding: .utf8)
            XCTAssertEqual(
                corrected,
                expected.code,
                #function + ".corrected file equals expected",
                file: before.file, line: before.line)
        } catch {
            XCTFail(
                "couldn't read file at path '\(path)': \(error)",
                file: before.file, line: before.line)
        }
    }
}

private extension String {
    func toStringLiteral() -> String {
        return "\"" + replacingOccurrences(of: "\n", with: "\\n") + "\""
    }
}

public func makeConfig(_ ruleConfiguration: Any?, _ identifier: String,
                       skipDisableCommandTests: Bool = false) -> Configuration? {
    let superfluousDisableCommandRuleIdentifier = SuperfluousDisableCommandRule.description.identifier
    let identifiers: Set<String> = skipDisableCommandTests ? [identifier]
        : [identifier, superfluousDisableCommandRuleIdentifier]

    if let ruleConfiguration, let ruleType = primaryRuleList.list[identifier] {
        // The caller has provided a custom configuration for the rule under test
        return (try? ruleType.init(configuration: ruleConfiguration)).flatMap { configuredRule in
            let rules = skipDisableCommandTests ? [configuredRule] : [configuredRule, SuperfluousDisableCommandRule()]
            return Configuration(
                rulesMode: .only(identifiers),
                allRulesWrapped: rules.map { ($0, false) }
            )
        }
    }
    return Configuration(rulesMode: .only(identifiers))
}

private func testCorrection(_ correction: (Example, Example),
                            configuration: Configuration,
                            testMultiByteOffsets: Bool) {
#if os(Linux)
    guard correction.0.testOnLinux else {
        return
    }
#endif
    var config = configuration
    if let correctionConfiguration = correction.0.configuration,
        case let .only(onlyRules) = configuration.rulesMode,
        let ruleToConfigure = (onlyRules.first { $0 != SuperfluousDisableCommandRule.description.identifier }),
        case let configDict = ["only_rules": onlyRules, ruleToConfigure: correctionConfiguration],
        let typedConfiguration = try? Configuration(dict: configDict) {
        config = configuration.merged(withChild: typedConfiguration, rootDirectory: configuration.rootDirectory)
    }

    config.assertCorrection(correction.0, expected: correction.1)
    if testMultiByteOffsets && correction.0.testMultiByteOffsets {
        config.assertCorrection(addEmoji(correction.0), expected: addEmoji(correction.1))
    }
}

private func addEmoji(_ example: Example) -> Example {
    return example.with(code: "/* 👨‍👩‍👧‍👦👨‍👩‍👧‍👦👨‍👩‍👧‍👦 */\n\(example.code)")
}

private func addShebang(_ example: Example) -> Example {
    return example.with(code: "#!/usr/bin/env swift\n\(example.code)")
}

public extension XCTestCase {
    var isRunningWithBazel: Bool { FileManager.default.currentDirectoryPath.contains("bazel-out") }

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

        guard let config = makeConfig(
            ruleConfiguration,
            ruleDescription.identifier,
            skipDisableCommandTests: skipDisableCommandTests) else {
                XCTFail("Failed to create configuration", file: (file), line: line)
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
                           requiresFileOnDisk: ruleDescription.requiresFileOnDisk, file: file, line: line)
        }
        func makeViolations(_ example: Example) -> [StyleViolation] {
            return violations(example, config: config, requiresFileOnDisk: ruleDescription.requiresFileOnDisk)
        }

        let ruleDescription = ruleDescription.focused()
        let (triggers, nonTriggers) = (ruleDescription.triggeringExamples, ruleDescription.nonTriggeringExamples)
        verify(triggers: triggers, nonTriggers: nonTriggers)

        if testMultiByteOffsets {
            verify(triggers: triggers.filter(\.testMultiByteOffsets).map(addEmoji),
                   nonTriggers: nonTriggers.filter(\.testMultiByteOffsets).map(addEmoji))
        }

        if testShebang {
            verify(triggers: triggers.filter(\.testMultiByteOffsets).map(addShebang),
                   nonTriggers: nonTriggers.filter(\.testMultiByteOffsets).map(addShebang))
        }

        // Comment doesn't violate
        if !skipCommentTests {
            let triggersToCheck = triggers.filter(\.testWrappingInComment)
            XCTAssertEqual(
                triggersToCheck.flatMap { makeViolations($0.with(code: "/*\n  " + $0.code + "\n */")) }.count,
                commentDoesntViolate ? 0 : triggersToCheck.count,
                "Violation(s) still triggered when code was nested inside a comment",
                file: (file), line: line
            )
        }

        // String doesn't violate
        if !skipStringTests {
            let triggersToCheck = triggers.filter(\.testWrappingInString)
            XCTAssertEqual(
                triggersToCheck.flatMap({ makeViolations($0.with(code: $0.code.toStringLiteral())) }).count,
                stringDoesntViolate ? 0 : triggersToCheck.count,
                "Violation(s) still triggered when code was nested inside a string literal",
                file: (file), line: line
            )
        }

        // Disabled rule doesn't violate and disable command isn't superfluous
        for command in disableCommands {
            let violationsPartionedByType = triggers
                .filter { $0.testDisableCommand }
                .map { $0.with(code: command + $0.code) }
                .flatMap { makeViolations($0) }
                .partitioned { $0.ruleIdentifier == SuperfluousDisableCommandRule.description.identifier }
            XCTAssert(violationsPartionedByType.first.isEmpty,
                      "Violation(s) still triggered although rule was disabled",
                      file: (file), line: line)
            XCTAssert(violationsPartionedByType.second.isEmpty,
                      "Disable command was superfluous since no violations(s) triggered",
                      file: (file), line: line)
        }
    }

    func verifyCorrections(_ ruleDescription: RuleDescription, config: Configuration,
                           disableCommands: [String], testMultiByteOffsets: Bool,
                           parserDiagnosticsDisabledForTests: Bool = true) {
        let ruleDescription = ruleDescription.focused()

        SwiftLintFramework.parserDiagnosticsDisabledForTests = parserDiagnosticsDisabledForTests

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
                let beforeDisabled = command + before.code
                let expectedCleaned = before.with(code: cleanedContentsAndMarkerOffsets(from: beforeDisabled).0)
                config.assertCorrection(expectedCleaned, expected: expectedCleaned)
            }
        }
    }

    private func verifyExamples(triggers: [Example], nonTriggers: [Example],
                                configuration config: Configuration, requiresFileOnDisk: Bool,
                                file callSiteFile: StaticString = #file,
                                line callSiteLine: UInt = #line) {
        // Non-triggering examples don't violate
        for nonTrigger in nonTriggers {
            let unexpectedViolations = violations(nonTrigger, config: config,
                                                  requiresFileOnDisk: requiresFileOnDisk)
            if unexpectedViolations.isEmpty { continue }
            let nonTriggerWithViolations = render(violations: unexpectedViolations, in: nonTrigger.code)
            XCTFail(
                "nonTriggeringExample violated: \n\(nonTriggerWithViolations)",
                file: nonTrigger.file,
                line: nonTrigger.line)
        }

        // Triggering examples violate
        for trigger in triggers {
            let triggerViolations = violations(trigger, config: config,
                                               requiresFileOnDisk: requiresFileOnDisk)

            // Triggering examples with violation markers violate at the marker's location
            let (cleanTrigger, markerOffsets) = cleanedContentsAndMarkerOffsets(from: trigger.code)
            if markerOffsets.isEmpty {
                if triggerViolations.isEmpty {
                    XCTFail(
                        "triggeringExample did not violate: \n```\n\(trigger.code)\n```",
                        file: trigger.file,
                        line: trigger.line)
                }
                continue
            }
            let file = SwiftLintFile.testFile(withContents: cleanTrigger)
            let expectedLocations = markerOffsets.map { Location(file: file, characterOffset: $0) }

            // Assert violations on unexpected location
            let violationsAtUnexpectedLocation = triggerViolations
                .filter { !expectedLocations.contains($0.location) }
            if !violationsAtUnexpectedLocation.isEmpty {
                XCTFail("triggeringExample violated at unexpected location: \n" +
                    "\(render(violations: violationsAtUnexpectedLocation, in: cleanTrigger))",
                    file: trigger.file,
                    line: trigger.line)
            }

            // Assert locations missing violation
            let violatedLocations = triggerViolations.map { $0.location }
            let locationsWithoutViolation = expectedLocations
                .filter { !violatedLocations.contains($0) }
            if !locationsWithoutViolation.isEmpty {
                XCTFail("triggeringExample did not violate at expected location: \n" +
                    "\(render(locations: locationsWithoutViolation, in: cleanTrigger))",
                    file: trigger.file,
                    line: trigger.line)
            }

            XCTAssertEqual(triggerViolations.count, expectedLocations.count,
                           file: trigger.file, line: trigger.line)
            for (triggerViolation, expectedLocation) in zip(triggerViolations, expectedLocations) {
                XCTAssertEqual(
                    triggerViolation.location, expectedLocation,
                    "'\(trigger)' violation didn't match expected location.",
                    file: trigger.file,
                    line: trigger.line)
            }
        }
    }

    // file and line parameters are first so we can use trailing closure syntax with the closure
    func checkError<T: Error & Equatable>(
        file: StaticString = #file,
        line: UInt = #line,
        _ error: T,
        closure: () throws -> Void) {
        do {
            try closure()
            XCTFail("No error caught", file: (file), line: line)
        } catch let rError as T {
            if error != rError {
                XCTFail("Wrong error caught. Got \(rError) but was expecting \(error)", file: (file), line: line)
            }
        } catch {
            XCTFail("Wrong error caught", file: (file), line: line)
        }
    }
}

private struct FocusedRuleDescription {
    let nonTriggeringExamples: [Example]
    let triggeringExamples: [Example]
    let corrections: [Example: Example]

    init(rule: RuleDescription) {
        let nonTriggering = rule.nonTriggeringExamples.filter(\.isFocused)
        let triggering = rule.triggeringExamples.filter(\.isFocused)
        let corrections = rule.corrections.filter { key, value in key.isFocused || value.isFocused }
        let anyFocused = nonTriggering.isNotEmpty || triggering.isNotEmpty || corrections.isNotEmpty

        if anyFocused {
            self.nonTriggeringExamples = nonTriggering
            self.triggeringExamples = triggering
            self.corrections = corrections
#if DISABLE_FOCUSED_EXAMPLES
            (nonTriggering + triggering + corrections.values).forEach { example in
                XCTFail("Focused examples are disabled", file: example.file, line: example.line)
            }
#endif
        } else {
            self.nonTriggeringExamples = rule.nonTriggeringExamples
            self.triggeringExamples = rule.triggeringExamples
            self.corrections = rule.corrections
        }
    }
}

private extension RuleDescription {
    func focused() -> FocusedRuleDescription {
        return FocusedRuleDescription(rule: self)
    }
}
