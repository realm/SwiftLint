import Foundation
import SourceKittenFramework

/// A rule configuration used for defining custom rules in yaml.
public struct RegexConfiguration<Parent: Rule>: SeverityBasedRuleConfiguration, Hashable,
                                                CacheDescriptionProvider, InlinableOptionType {
    /// The identifier for this custom rule.
    public let identifier: String
    /// The name for this custom rule.
    public var name: String?
    /// The message to be presented when producing violations.
    public var message = "Regex matched"
    /// The regular expression to apply to trigger violations for this custom rule.
    @ConfigurationElement(key: "regex")
    package var regex: RegularExpression! // swiftlint:disable:this implicitly_unwrapped_optional
    /// Regular expressions to include when matching the file path.
    public var included: [RegularExpression] = []
    /// Regular expressions to exclude when matching the file path.
    public var excluded: [RegularExpression] = []
    /// The syntax kinds to exclude from matches. If the regex matched syntax kinds from this list, it would
    /// be ignored and not count as a rule violation.
    public var excludedMatchKinds = Set<SyntaxKind>()
    @ConfigurationElement(key: "severity")
    public var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    /// The index of the regex capture group to match.
    public var captureGroup = 0

    public var cacheDescription: String {
        let jsonObject: [String] = [
            identifier,
            name ?? "",
            message,
            regex.pattern,
            included.map(\.pattern).joined(separator: ","),
            excluded.map(\.pattern).joined(separator: ","),
            SyntaxKind.allKinds.subtracting(excludedMatchKinds)
                .map(\.rawValue).sorted(by: <).joined(separator: ","),
            severity.rawValue,
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject),
          let jsonString = String(data: jsonData, encoding: .utf8) {
              return jsonString
        }
        queuedFatalError("Could not serialize regex configuration for cache")
    }

    /// The `RuleDescription` for the custom rule defined here.
    public var description: RuleDescription {
        RuleDescription(identifier: identifier, name: name ?? identifier,
                        description: "", kind: .style)
    }

    /// Create a `RegexConfiguration` with the specified identifier, with other properties to be set later.
    ///
    /// - parameter identifier: The rule identifier to use.
    public init(identifier: String) {
        self.identifier = identifier
    }

    public mutating func apply(configuration: Any) throws {
        guard let configurationDict = configuration as? [String: Any],
              let regexString = configurationDict[$regex.key] as? String else {
            throw Issue.invalidConfiguration(ruleID: Parent.identifier)
        }

        regex = try .from(pattern: regexString, for: Parent.identifier)

        if let includedString = configurationDict["included"] as? String {
            included = [try .from(pattern: includedString, for: Parent.identifier)]
        } else if let includedArray = configurationDict["included"] as? [String] {
            included = try includedArray.map { pattern in
                try .from(pattern: pattern, for: Parent.identifier)
            }
        }

        if let excludedString = configurationDict["excluded"] as? String {
            excluded = [try .from(pattern: excludedString, for: Parent.identifier)]
        } else if let excludedArray = configurationDict["excluded"] as? [String] {
            excluded = try excludedArray.map { pattern in
                try .from(pattern: pattern, for: Parent.identifier)
            }
        }

        if let name = configurationDict["name"] as? String {
            self.name = name
        }
        if let message = configurationDict["message"] as? String {
            self.message = message
        }
        if let severityString = configurationDict[$severityConfiguration.key] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
        if let captureGroup = configurationDict["capture_group"] as? Int {
            guard (0 ... regex.numberOfCaptureGroups).contains(captureGroup) else {
                throw Issue.invalidConfiguration(ruleID: Parent.identifier)
            }
            self.captureGroup = captureGroup
        }

        self.excludedMatchKinds = try self.excludedMatchKinds(from: configurationDict)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }

    package func shouldValidate(filePath: String) -> Bool {
        let pathRange = filePath.fullNSRange
        let isIncluded = included.isEmpty || included.contains { regex in
            regex.regex.firstMatch(in: filePath, range: pathRange) != nil
        }

        guard isIncluded else {
            return false
        }

        return excluded.allSatisfy { regex in
            regex.regex.firstMatch(in: filePath, range: pathRange) == nil
        }
    }

    private func excludedMatchKinds(from configurationDict: [String: Any]) throws -> Set<SyntaxKind> {
        let matchKinds = [String].array(of: configurationDict["match_kinds"])
        let excludedMatchKinds = [String].array(of: configurationDict["excluded_match_kinds"])

        switch (matchKinds, excludedMatchKinds) {
        case (.some(let matchKinds), nil):
            return SyntaxKind.allKinds.subtracting(try toSyntaxKinds(matchKinds))
        case (nil, .some(let excludedMatchKinds)):
            return try toSyntaxKinds(excludedMatchKinds)
        case (nil, nil):
            return .init()
        case (.some, .some):
            throw Issue.genericWarning(
                "The configuration keys 'match_kinds' and 'excluded_match_kinds' cannot appear at the same time."
            )
        }
    }

    private func toSyntaxKinds(_ names: [String]) throws -> Set<SyntaxKind> {
        let kinds = try names.map {
            if let kind = SyntaxKind(shortName: $0) {
                return kind
            }
            throw Issue.invalidConfiguration(ruleID: Parent.identifier)
        }
        return Set(kinds)
    }
}
