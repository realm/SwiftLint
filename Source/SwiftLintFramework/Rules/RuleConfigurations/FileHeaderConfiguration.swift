import Foundation
import SourceKittenFramework

public struct FileHeaderConfiguration: RuleConfiguration, Equatable {
    private static let fileNamePlaceholder = "SWIFTLINT_CURRENT_FILENAME"
    private static let stringRegexOptions: NSRegularExpression.Options = [.ignoreMetacharacters]
    private static let patternRegexOptions: NSRegularExpression.Options =
        [.anchorsMatchLines, .dotMatchesLineSeparators]

    private(set) var severityConfiguration = SeverityConfiguration(.warning)
    private var requiredString: String?
    private var requiredPattern: String?
    private var forbiddenString: String?
    private var forbiddenPattern: String?

    private var _forbiddenRegex: NSRegularExpression?
    private var _requiredRegex: NSRegularExpression?

    private static let defaultRegex = regex("\\bCopyright\\b", options: [.caseInsensitive])

    public var consoleDescription: String {
        let requiredStringDescription = requiredString ?? "None"
        let requiredPatternDescription = requiredPattern ?? "None"
        let forbiddenStringDescription = forbiddenString ?? "None"
        let forbiddenPatternDescription = forbiddenPattern ?? "None"

        return severityConfiguration.consoleDescription +
            ", required_string: \(requiredStringDescription)" +
            ", required_pattern: \(requiredPatternDescription)" +
            ", forbidden_string: \(forbiddenStringDescription)" +
            ", forbidden_pattern: \(forbiddenPatternDescription)"
    }

    public init() {}

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: String] else {
            throw ConfigurationError.unknownConfiguration
        }

        // Cache the created regexes if possible.
        // If the pattern contains the SWIFTLINT_CURRENT_FILENAME placeholder,
        // the regex will be recompiled for each validated file.
        if let requiredString = configuration["required_string"] {
            self.requiredString = requiredString
            if !requiredString.contains(FileHeaderConfiguration.fileNamePlaceholder) {
                _requiredRegex = try NSRegularExpression(pattern: requiredString,
                                                         options: FileHeaderConfiguration.stringRegexOptions)
            }
        } else if let requiredPattern = configuration["required_pattern"] {
            self.requiredPattern = requiredPattern
            if !requiredPattern.contains(FileHeaderConfiguration.fileNamePlaceholder) {
                _requiredRegex = try .cached(pattern: requiredPattern)
            }
        }

        if let forbiddenString = configuration["forbidden_string"] {
            self.forbiddenString = forbiddenString
            if !forbiddenString.contains(FileHeaderConfiguration.fileNamePlaceholder) {
                _forbiddenRegex = try NSRegularExpression(pattern: forbiddenString,
                                                          options: FileHeaderConfiguration.stringRegexOptions)
            }
        } else if let forbiddenPattern = configuration["forbidden_pattern"] {
            self.forbiddenPattern = forbiddenPattern
            if !forbiddenPattern.contains(FileHeaderConfiguration.fileNamePlaceholder) {
                _forbiddenRegex = try .cached(pattern: forbiddenPattern)
            }
        }

        if let severityString = configuration["severity"] {
            try severityConfiguration.apply(configuration: severityString)
        }
    }

    private func makeRegex(for file: File, using pattern: String,
                           options: NSRegularExpression.Options, escapeFileName: Bool) -> NSRegularExpression? {

        // Recompile the regex for this file...
        let replacedPattern = file.path.map { path in
            let fileName = path.bridge().lastPathComponent

            // Replace SWIFTLINT_CURRENT_FILENAME with the filename.
            let escapedName = escapeFileName ? NSRegularExpression.escapedPattern(for: fileName) : fileName
            return pattern.replacingOccurrences(of: FileHeaderConfiguration.fileNamePlaceholder,
                                                with: escapedName)
        } ?? pattern

        do {
            return try NSRegularExpression(pattern: replacedPattern, options: options)
        } catch {
            queuedFatalError("Failed to compile pattern '\(replacedPattern)'")
        }
    }

    private func regexFromString(for file: File, using pattern: String) -> NSRegularExpression? {
        return makeRegex(for: file, using: pattern, options: FileHeaderConfiguration.stringRegexOptions,
                         escapeFileName: false)
    }

    private func regexFromPattern(for file: File, using pattern: String) -> NSRegularExpression? {
        return makeRegex(for: file, using: pattern, options: FileHeaderConfiguration.patternRegexOptions,
                         escapeFileName: true)
    }

    func forbiddenRegex(for file: File) -> NSRegularExpression? {
        if _forbiddenRegex != nil {
            return _forbiddenRegex
        }

        if let regex = forbiddenString.flatMap({ regexFromString(for: file, using: $0) }) {
            return regex
        }

        if let regex = forbiddenPattern.flatMap({ regexFromPattern(for: file, using: $0) }) {
            return regex
        }

        if requiredPattern == nil, requiredString == nil {
            return FileHeaderConfiguration.defaultRegex
        }

        return nil
    }

    func requiredRegex(for file: File) -> NSRegularExpression? {
        if _requiredRegex != nil {
            return _requiredRegex
        }

        if let regex = requiredString.flatMap({ regexFromString(for: file, using: $0) }) {
            return regex
        }

        return requiredPattern.flatMap { regexFromPattern(for: file, using: $0) }
    }
}

public func == (lhs: FileHeaderConfiguration,
                rhs: FileHeaderConfiguration) -> Bool {
    return lhs.severityConfiguration == rhs.severityConfiguration
}
