//
//  LinterCache.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 12/27/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public enum LinterCacheError: Error {
    case invalidFormat
    case differentVersion
}

public struct LinterCache {
    private var cache: [String: Any]

    public init(currentVersion: Version = .current) {
        cache = [String: Any]()
        cache["version"] = currentVersion.value
    }

    public init(contentsOf url: URL, currentVersion: Version = .current) throws {
        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        guard let dictionary = json as? [String: Any] else {
            throw LinterCacheError.invalidFormat
        }

        guard let version = dictionary["version"] as? String, version == currentVersion.value else {
            throw LinterCacheError.differentVersion
        }

        cache = dictionary
    }

    public mutating func cacheFile(_ file: String, violations: [StyleViolation], hash: Int) {

        var entry = [String: Any]()
        var fileViolations = entry["violations"] as? [[String: Any]] ?? []

        for violation in violations {
            fileViolations.append(dictionaryForViolation(violation))
        }

        entry["violations"] = fileViolations
        entry["hash"] = hash
        cache[file] = entry
    }

    public func violations(for file: String, hash: Int) -> [StyleViolation]? {
        guard let entry = cache[file] as? [String: Any],
            let cacheHash = entry["hash"] as? Int,
            cacheHash == hash,
            let violations = entry["violations"] as? [[String: Any]] else {
            return nil
        }

        return violations.flatMap { StyleViolation.fromCache($0, file: file) }
    }

    public func save(to url: URL) throws {
        let json = toJSON(cache)
        try json.write(to: url, atomically: true, encoding: .utf8)
    }

    private func dictionaryForViolation(_ violation: StyleViolation) -> [String: Any] {
        return [
            "line": violation.location.line ?? NSNull() as Any,
            "character": violation.location.character ?? NSNull() as Any,
            "severity": violation.severity.rawValue,
            "type": violation.ruleDescription.name,
            "rule_id": violation.ruleDescription.identifier,
            "reason": violation.reason
        ]
    }
}

extension StyleViolation {
    fileprivate static func fromCache(_ cache: [String: Any], file: String) -> StyleViolation? {
        guard let severity = (cache["severity"] as? String).flatMap(ViolationSeverity.init(identifier:)),
            let name = cache["type"] as? String,
            let ruleId = cache["rule_id"] as? String,
            let reason = cache["reason"] as? String else {
                return nil
        }

        let line = cache["line"] as? Int
        let character = cache["character"] as? Int

        let ruleDescription = RuleDescription(identifier: ruleId, name: name, description: reason)
        let location = Location(file: file, line: line, character: character)
        let violation = StyleViolation(ruleDescription: ruleDescription, severity: severity,
                                       location: location, reason: reason)

        return violation
    }
}
