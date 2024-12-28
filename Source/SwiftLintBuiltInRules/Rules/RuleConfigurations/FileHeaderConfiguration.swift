import Foundation
import SourceKittenFramework
import SwiftLintCore

struct FileHeaderConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = FileHeaderRule

    private static let fileNamePlaceholder = "SWIFTLINT_CURRENT_FILENAME"
    private static let stringRegexOptions: NSRegularExpression.Options = [.ignoreMetacharacters]
    private static let patternRegexOptions: NSRegularExpression.Options =
        [.anchorsMatchLines, .dotMatchesLineSeparators]

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "required_string")
    private var requiredString: String?
    @ConfigurationElement(key: "required_pattern")
    private var requiredPattern: String?
    @ConfigurationElement(key: "forbidden_string")
    private var forbiddenString: String?
    @ConfigurationElement(key: "forbidden_pattern")
    private var forbiddenPattern: String?

    private var _forbiddenRegex: RegularExpression?
    private var _requiredRegex: RegularExpression?

    private static let defaultRegex = regex("\\bCopyright\\b", options: [.caseInsensitive])

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: String] else {
            throw Issue.invalidConfiguration(ruleID: Parent.identifier)
        }

        // Cache the created regexes if possible.
        // If the pattern contains the SWIFTLINT_CURRENT_FILENAME placeholder,
        // the regex will be recompiled for each validated file.
        if let requiredString = configuration[$requiredString.key] {
            self.requiredString = requiredString
            if !requiredString.contains(Self.fileNamePlaceholder) {
                _requiredRegex = try .from(
                    pattern: requiredString,
                    options: Self.stringRegexOptions,
                    for: Parent.identifier
                )
            }
        } else if let requiredPattern = configuration[$requiredPattern.key] {
            self.requiredPattern = requiredPattern
            if !requiredPattern.contains(Self.fileNamePlaceholder) {
                _requiredRegex = try .from(pattern: requiredPattern, for: Parent.identifier)
            }
        }

        if let forbiddenString = configuration[$forbiddenString.key] {
            self.forbiddenString = forbiddenString
            if !forbiddenString.contains(Self.fileNamePlaceholder) {
                _forbiddenRegex = try .from(
                    pattern: forbiddenString,
                    options: Self.stringRegexOptions,
                    for: Parent.identifier
                )
            }
        } else if let forbiddenPattern = configuration[$forbiddenPattern.key] {
            self.forbiddenPattern = forbiddenPattern
            if !forbiddenPattern.contains(Self.fileNamePlaceholder) {
                _forbiddenRegex = try .from(pattern: forbiddenPattern, for: Parent.identifier)
            }
        }

        if let severityString = configuration[$severityConfiguration.key] {
            try severityConfiguration.apply(configuration: severityString)
        }
    }

    private func makeRegex(for file: SwiftLintFile,
                           using pattern: String,
                           options: NSRegularExpression.Options,
                           escapeFileName: Bool) -> NSRegularExpression? {
        // Recompile the regex for this file...
        let replacedPattern = file.path.map { path in
            let fileName = path.bridge().lastPathComponent

            // Replace SWIFTLINT_CURRENT_FILENAME with the filename.
            let escapedName = escapeFileName ? NSRegularExpression.escapedPattern(for: fileName) : fileName
            return pattern.replacingOccurrences(of: Self.fileNamePlaceholder,
                                                with: escapedName)
        } ?? pattern

        do {
            return try NSRegularExpression(pattern: replacedPattern, options: options)
        } catch {
            queuedFatalError("Failed to compile pattern '\(replacedPattern)'")
        }
    }

    private func regexFromString(for file: SwiftLintFile, using pattern: String) -> NSRegularExpression? {
        makeRegex(for: file, using: pattern, options: Self.stringRegexOptions, escapeFileName: false)
    }

    private func regexFromPattern(for file: SwiftLintFile, using pattern: String) -> NSRegularExpression? {
        makeRegex(for: file, using: pattern, options: Self.patternRegexOptions, escapeFileName: true)
    }

    func forbiddenRegex(for file: SwiftLintFile) -> NSRegularExpression? {
        if _forbiddenRegex != nil {
            return _forbiddenRegex?.regex
        }

        if let regex = forbiddenString.flatMap({ regexFromString(for: file, using: $0) }) {
            return regex
        }

        if let regex = forbiddenPattern.flatMap({ regexFromPattern(for: file, using: $0) }) {
            return regex
        }

        if requiredPattern == nil, requiredString == nil {
            return Self.defaultRegex
        }

        return nil
    }

    func requiredRegex(for file: SwiftLintFile) -> NSRegularExpression? {
        if _requiredRegex != nil {
            return _requiredRegex?.regex
        }

        if let regex = requiredString.flatMap({ regexFromString(for: file, using: $0) }) {
            return regex
        }

        return requiredPattern.flatMap { regexFromPattern(for: file, using: $0) }
    }
}
