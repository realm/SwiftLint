import Foundation
import SourceKittenFramework
@testable import SwiftLintFramework

enum TestHelpers {
    static let allRuleIdentifiers = Array(masterRuleList.list.keys)

    static let violationMarker = "↓"

    static func cleanedContentsAndMarkerOffsets(from contents: String) -> (String, [Int]) {
        var contents = contents.bridge()
        var markerOffsets = [Int]()
        var markerRange = contents.range(of: violationMarker)
        while markerRange.location != NSNotFound {
            markerOffsets.append(markerRange.location)
            contents = contents.replacingCharacters(in: markerRange, with: "").bridge()
            markerRange = contents.range(of: TestHelpers.violationMarker)
        }
        return (contents.bridge(), markerOffsets.sorted())
    }

    static func testCorrection(_ correction: (Example, Example),
                               configuration config: Configuration,
                               testMultiByteOffsets: Bool) {
        config.assertCorrection(correction.0, expected: correction.1)
        if testMultiByteOffsets {
            config.assertCorrection(correction.0.addingEmoji, expected: correction.1.addingEmoji)
        }
    }

    static func render(locations: [Location], in contents: String) -> String {
        var contents = StringView(contents).lines.map { $0.content }
        for location in locations.sorted(by: > ) {
            guard let line = location.line, let character = location.character else { continue }
            let content = NSMutableString(string: contents[line - 1])
            content.insert("↓", at: character - 1)
            contents[line - 1] = content.bridge()
        }
        return (["```"] + contents + ["```"]).joined(separator: "\n")
    }

    static func render(violations: [StyleViolation], in contents: String) -> String {
        var contents = StringView(contents).lines.map { $0.content }
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

    static func violations(_ example: Example, config: Configuration = Configuration()!,
                           requiresFileOnDisk: Bool = false) -> [StyleViolation] {
        SwiftLintFile.clearCaches()
        let stringStrippingMarkers = example.removingViolationMarkers()
        guard requiresFileOnDisk else {
            let file = SwiftLintFile(contents: stringStrippingMarkers.code)
            let storage = RuleStorage()
            let linter = Linter(file: file, configuration: config).collect(into: storage)
            return linter.styleViolations(using: storage)
        }

        let file = SwiftLintFile.temporary(withContents: stringStrippingMarkers.code)
        let storage = RuleStorage()
        let collecter = Linter(file: file, configuration: config, compilerArguments: file.makeCompilerArguments())
        let linter = collecter.collect(into: storage)
        return linter.styleViolations(using: storage).withoutFiles()
    }

    static func makeConfig(_ ruleConfiguration: Any?, _ identifier: String,
                           skipDisableCommandTests: Bool = false) -> Configuration? {
        let superfluousDisableCommandRuleIdentifier = SuperfluousDisableCommandRule.description.identifier
        let identifiers = skipDisableCommandTests
            ? [identifier]
            : [identifier, superfluousDisableCommandRuleIdentifier]

        if let ruleConfiguration = ruleConfiguration, let ruleType = masterRuleList.list[identifier] {
            // The caller has provided a custom configuration for the rule under test
            return (try? ruleType.init(configuration: ruleConfiguration)).flatMap { configuredRule in
                let rules = skipDisableCommandTests
                    ? [configuredRule]
                    : [configuredRule, SuperfluousDisableCommandRule()]
                return Configuration(rulesMode: .whitelisted(identifiers), configuredRules: rules)
            }
        }
        return Configuration(rulesMode: .whitelisted(identifiers))
    }
}
