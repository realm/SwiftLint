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
    case differentConfiguration
}

public final class LinterCache {
    private var cache: [String: Any]
    private let lock = NSLock()

    public init(currentVersion: Version = .current, configurationDescription: String? = nil) {
        cache = [
            "version": currentVersion.value,
            "files": [:]
        ]
        cache["configuration"] = configurationDescription
    }

    public init(cache: Any, currentVersion: Version = .current, configurationDescription: String? = nil) throws {
        guard let dictionary = cache as? [String: Any] else {
            throw LinterCacheError.invalidFormat
        }

        guard dictionary["version"] as? String == currentVersion.value else {
            throw LinterCacheError.differentVersion
        }

        guard dictionary["configuration"] as? String == configurationDescription else {
            throw LinterCacheError.differentConfiguration
        }

        self.cache = dictionary
    }

    public convenience init(contentsOf url: URL, currentVersion: Version = .current,
                            configurationDescription: String? = nil) throws {
        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        try self.init(cache: json, currentVersion: currentVersion,
                      configurationDescription: configurationDescription)
    }

    public func cache(violations: [StyleViolation], forFile file: String) {
        guard let lastModified = FileManager.default.modifiedDate(forFileAtPath: file) else {
            return
        }
        lock.lock()
        var filesCache = (cache["files"] as? [String: Any]) ?? [:]
        filesCache[file] = [
            "violations": violations.map(dictionary(for:)),
            "last_modified": Int(lastModified.timeIntervalSinceReferenceDate)
        ]
        cache["files"] = filesCache
        lock.unlock()
    }

    public func violations(forFile file: String) -> [StyleViolation]? {
        guard let lastModified = FileManager.default.modifiedDate(forFileAtPath: file) else {
            return nil
        }
        lock.lock()

        guard let filesCache = cache["files"] as? [String: Any],
            let entry = filesCache[file] as? [String: Any],
            let cacheLastModified = entry["last_modified"] as? Int,
            cacheLastModified == Int(lastModified.timeIntervalSinceReferenceDate),
            let violations = entry["violations"] as? [[String: Any]] else {
                lock.unlock()
                return nil
        }

        lock.unlock()
        return violations.flatMap { StyleViolation.from(cache: $0, file: file) }
    }

    public func save(to url: URL) throws {
        lock.lock()
        let json = toJSON(cache)
        lock.unlock()
        try json.write(to: url, atomically: true, encoding: .utf8)
    }

    private func dictionary(for violation: StyleViolation) -> [String: Any] {
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
    fileprivate static func from(cache: [String: Any], file: String) -> StyleViolation? {
        guard let severity = (cache["severity"] as? String).flatMap({ ViolationSeverity(rawValue: $0) }),
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
