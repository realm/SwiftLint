import Foundation
import SourceKittenFramework

public struct FileHeaderConfiguration: RuleConfiguration, Equatable {
    private static let fileNamePlaceholder = "SWIFTLINT_CURRENT_FILENAME"
    private(set) var severityConfiguration = SeverityConfiguration(.warning)
    private var requiredString: String?
    private var requiredPattern: String?
    private var forbiddenString: String?
    private var forbiddenPattern: String?

    private var _forbiddenRegex: NSRegularExpression?
    private var _requiredRegex: NSRegularExpression?
    private(set) var forbiddenRegexQ: NSRegularExpression? {
        get {
            if _forbiddenRegex != nil {
                return _forbiddenRegex
            }

            if _requiredRegex == nil {
                return FileHeaderConfiguration.defaultRegex
            }

            return nil
        }
        set {
            _forbiddenRegex = newValue
        }
    }

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

        if let requiredString = configuration["required_string"] {
            self.requiredString = requiredString
            _requiredRegex = try NSRegularExpression(pattern: requiredString,
                                                     options: [.ignoreMetacharacters])
        } else if let requiredPattern = configuration["required_pattern"] {
            self.requiredPattern = requiredPattern

            // Cache the created regex of requiredPattern if possible.
            // If requiredPattern contains the SWIFTLINT_CURRENT_FILENAME placeholder,
            // the regex will be recompiled for each validated file.
            if !requiredPattern.contains(FileHeaderConfiguration.fileNamePlaceholder) {
                _requiredRegex = try .cached(pattern: requiredPattern)
            }
        }

        if let forbiddenString = configuration["forbidden_string"] {
            self.forbiddenString = forbiddenString
            _forbiddenRegex = try NSRegularExpression(pattern: forbiddenString,
                                                      options: [.ignoreMetacharacters])
        } else if let forbiddenPattern = configuration["forbidden_pattern"] {
            self.forbiddenPattern = forbiddenPattern

            // Cache the created regex of forbiddenPattern if possible.
            // If forbiddenPattern contains the SWIFTLINT_CURRENT_FILENAME placeholder,
            // the regex will be recompiled for each validated file.
            if !forbiddenPattern.contains(FileHeaderConfiguration.fileNamePlaceholder) {
                _forbiddenRegex = try .cached(pattern: forbiddenPattern)
            }
        }

        if let severityString = configuration["severity"] {
            try severityConfiguration.apply(configuration: severityString)
        }
    }

    private func makeRegex(for file: File, using pattern: String) -> NSRegularExpression? {
        // Recompile the regex for this file
        guard let fileName = file.path?.bridge().lastPathComponent else {
            queuedFatalError("Expected to validate a file.")
        }

        // Replace SWIFTLINT_CURRENT_FILENAME with the filename.
        let escapedName = NSRegularExpression.escapedPattern(for: fileName)
        let replacedPattern = pattern.replacingOccurrences(of: FileHeaderConfiguration.fileNamePlaceholder,
                                                           with: escapedName)
        do {
            return try NSRegularExpression(pattern: replacedPattern,
                                           options: [.anchorsMatchLines, .dotMatchesLineSeparators])
        } catch {
            queuedFatalError("Failed to compile pattern '\(replacedPattern)'")
        }
    }

    func forbiddenRegex(for file: File) -> NSRegularExpression? {
        if _forbiddenRegex != nil {
            return _forbiddenRegex
        }

        if let regex = forbiddenPattern.flatMap({ makeRegex(for: file, using: $0) }) {
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

        return requiredPattern.flatMap { makeRegex(for: file, using: $0) }
    }
}

public func == (lhs: FileHeaderConfiguration,
                rhs: FileHeaderConfiguration) -> Bool {
    return lhs.severityConfiguration == rhs.severityConfiguration
}
