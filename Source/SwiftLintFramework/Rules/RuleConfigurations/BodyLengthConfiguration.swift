//
//  BodyLengthConfiguration.swift
//  SwiftLint
//
//  Created by Daniel Rodriguez Troitino on 3/16/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation

public struct BodyLengthConfiguration: RuleConfiguration, Equatable {
    public var consoleDescription: String {
        return severityLevels.consoleDescription
    }

    private var severityLevels: SeverityLevelsConfiguration
    private(set) var excluded: Set<NSRegularExpression>

    var warning: Int {
        return severityLevels.warning
    }

    var error: Int? {
        return severityLevels.error
    }

    var params: [RuleParameter<Int>] {
        return severityLevels.params
    }

    func isExcluded(_ name: String?) -> Bool {
        guard let name = name else { return false }

        let range = NSRange(location: 0, length: name.characters.count)
        for regex in excluded {
            if regex.firstMatch(in: name, options: [], range: range) != nil {
                return true
            }
        }

        return false
    }

    public init(warning: Int, error: Int, excluded: Set<NSRegularExpression> = []) {
        severityLevels = SeverityLevelsConfiguration(warning: warning, error: error)
        self.excluded = excluded
    }

    public mutating func apply(configuration: Any) throws {
        // The composition with SeverityLevelsConfiguration is tricky.
        // We know that the formats accepted right now cannot be compatible with our format,
        // but we cannot be sure about the future.
        do {
            try severityLevels.apply(configuration: configuration)
            return
        } catch {
            // Nothing to be done here.
        }

        guard let configurationDict = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let excluded = [String].array(of: configurationDict["excluded"]) {
            self.excluded = Set(try excluded.map { try .cached(pattern: $0) })
        }

        // At this point we know configurationDict is a dictionary, and at least one value
        // wasn’t an Int (knowledge from SeverityLevelsConfiguration). If we remove a
        // possible excluded, we either end up with a dictionary good for SeverityLevels
        // or we might have some extra invalid key, in any case, the code there will take
        // care of it.
        var cleanConfiguration = configurationDict
        _ = cleanConfiguration.removeValue(forKey: "excluded")

        if !cleanConfiguration.isEmpty {
            try severityLevels.apply(configuration: cleanConfiguration)
        }
    }
}

public func == (lhs: BodyLengthConfiguration, rhs: BodyLengthConfiguration) -> Bool {
    return lhs.warning == rhs.warning &&
        lhs.error == rhs.error &&
        zip(lhs.excluded, rhs.excluded).reduce(true) { $0 && (RegexCacheKey($1.0) == RegexCacheKey($1.1)) }
}

extension RegexCacheKey {
    init(_ regex: NSRegularExpression) {
        pattern = regex.pattern
        options = regex.options
    }
}
