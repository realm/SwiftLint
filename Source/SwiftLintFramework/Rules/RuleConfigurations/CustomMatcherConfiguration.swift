import Foundation
import SourceKittenFramework

public struct AST: Codable, Hashable, CacheDescriptionProvider {
    var consoleDescription: String { "" }
    var cacheDescription: String { "" }
}

public enum ContentMatcher: Hashable, CacheDescriptionProvider {
    case regex(regex: NSRegularExpression, captureGroup: Int)
    case ast(AST)

    var consoleDescription: String {
        switch self {
        case .regex(let regex, _):
            return regex.pattern
        case .ast(let ast):
            return ast.consoleDescription
        }
    }

    var cacheDescription: String {
        switch self {
        case .regex(let regex, _):
            return regex.pattern
        case .ast(let ast):
            return ast.cacheDescription
        }
    }

    init?(configuration: [String: Any]) throws {
        let captureGroup = configuration["capture_group"] as? Int ?? 0
        if let regexString = configuration["regex"] as? String {
            let regex = try NSRegularExpression.cached(pattern: regexString)

            guard (0 ... regex.numberOfCaptureGroups).contains(captureGroup) else {
                throw ConfigurationError.unknownConfiguration
            }

            self = .regex(regex: regex, captureGroup: captureGroup)
            return
        }

        if let astString = configuration["ast"] as? String {
            guard let astData = astString.data(using: .utf8) else {
                throw ConfigurationError.unknownConfiguration
            }
            self = try .ast(JSONDecoder().decode(AST.self, from: astData))
            return
        }

        throw ConfigurationError.unknownConfiguration
    }
}

public struct CustomMatcherConfiguration: RuleConfiguration, Hashable, CacheDescriptionProvider {
    public let identifier: String
    public var name: String?
    public var message = "Regex matched."
    public var matcher: ContentMatcher!
    public var included: NSRegularExpression?
    public var excluded: NSRegularExpression?
    public var excludedMatchKinds = Set<SyntaxKind>()
    public var severityConfiguration = SeverityConfiguration(.warning)

    public var severity: ViolationSeverity {
        return severityConfiguration.severity
    }

    public var consoleDescription: String {
        return "\(severity.rawValue): \(matcher.consoleDescription)"
    }

    internal var cacheDescription: String {
        let jsonObject: [String] = [
            identifier,
            name ?? "",
            message,
            matcher.cacheDescription,
            included?.pattern ?? "",
            excluded?.pattern ?? "",
            SyntaxKind.allKinds.subtracting(excludedMatchKinds)
                .map({ $0.rawValue }).sorted(by: <).joined(separator: ","),
            severityConfiguration.consoleDescription
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject),
          let jsonString = String(data: jsonData, encoding: .utf8) {
              return jsonString
        }
        queuedFatalError("Could not serialize custom configuration for cache")
    }

    public var description: RuleDescription {
        return RuleDescription(identifier: identifier, name: name ?? identifier,
                               description: "", kind: .style)
    }

    public init(identifier: String) {
        self.identifier = identifier
    }

    public mutating func apply(configuration: Any) throws {
        guard let configurationDict = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        matcher = try ContentMatcher(configuration: configurationDict)

        if let includedString = configurationDict["included"] as? String {
            included = try .cached(pattern: includedString)
        }

        if let excludedString = configurationDict["excluded"] as? String {
            excluded = try .cached(pattern: excludedString)
        }

        if let name = configurationDict["name"] as? String {
            self.name = name
        }
        if let message = configurationDict["message"] as? String {
            self.message = message
        }
        if let severityString = configurationDict["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }

        self.excludedMatchKinds = try self.excludedMatchKinds(from: configurationDict)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }

    private func excludedMatchKinds(from configurationDict: [String: Any]) throws -> Set<SyntaxKind> {
        let matchKinds = [String].array(of: configurationDict["match_kinds"])
        let excludedMatchKinds = [String].array(of: configurationDict["excluded_match_kinds"])

        switch (matchKinds, excludedMatchKinds) {
        case (.some(let matchKinds), nil):
            let includedKinds = Set(try matchKinds.map({ try SyntaxKind(shortName: $0) }))
            return SyntaxKind.allKinds.subtracting(includedKinds)
        case (nil, .some(let excludedMatchKinds)):
            return Set(try excludedMatchKinds.map({ try SyntaxKind(shortName: $0) }))
        case (nil, nil):
            return .init()
        case (.some, .some):
            throw ConfigurationError.ambiguousMatchKindParameters
        }
    }
}
