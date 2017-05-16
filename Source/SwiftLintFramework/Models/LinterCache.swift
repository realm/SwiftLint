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
    case differentConfiguration
}

public final class LinterCache {
    private var cache: [String: Any]
    private let lock = NSLock()
    internal lazy var fileManager: LintableFileManager = FileManager.default

    public init(configurationDescription: String? = nil) {
        cache = [Key.files.rawValue: [:]]
        cache[Key.configuration.rawValue] = configurationDescription
    }

    public init(cache: Any, configurationDescription: String? = nil) throws {
        guard let dictionary = cache as? [String: Any] else {
            throw LinterCacheError.invalidFormat
        }

        guard dictionary[Key.configuration.rawValue] as? String == configurationDescription else {
            throw LinterCacheError.differentConfiguration
        }

        self.cache = dictionary
    }

    public convenience init(contentsOf url: URL, configurationDescription: String? = nil) throws {
        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        try self.init(cache: json, configurationDescription: configurationDescription)
    }

    public func cache(violations: [StyleViolation], forFile file: String) {
        guard let lastModification = fileManager.modificationDate(forFileAtPath: file) else {
            return
        }

        lock.lock()
        var filesCache = (cache[Key.files.rawValue] as? [String: Any]) ?? [:]
        filesCache[file] = [
            Key.violations.rawValue: violations.map(dictionary(for:)),
            Key.lastModification.rawValue: lastModification.timeIntervalSinceReferenceDate
        ]
        cache[Key.files.rawValue] = filesCache
        lock.unlock()
    }

    public func violations(forFile file: String) -> [StyleViolation]? {
        guard let lastModification = fileManager.modificationDate(forFileAtPath: file) else {
            return nil
        }

        lock.lock()

        guard let filesCache = cache[Key.files.rawValue] as? [String: Any],
            let entry = filesCache[file] as? [String: Any],
            let cacheLastModification = entry[Key.lastModification.rawValue] as? TimeInterval,
            cacheLastModification == lastModification.timeIntervalSinceReferenceDate,
            let violations = entry[Key.violations.rawValue] as? [[String: Any]] else {
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
            Key.line.rawValue: violation.location.line ?? NSNull() as Any,
            Key.character.rawValue: violation.location.character ?? NSNull() as Any,
            Key.severity.rawValue: violation.severity.rawValue,
            Key.type.rawValue: violation.ruleDescription.name,
            Key.ruleID.rawValue: violation.ruleDescription.identifier,
            Key.reason.rawValue: violation.reason
        ]
    }
}

extension LinterCache {
    fileprivate enum Key: String {
        case character
        case configuration
        case files
        case lastModification = "last_modification"
        case line
        case reason
        case ruleID = "rule_id"
        case severity
        case type
        case violations
    }
}

extension StyleViolation {
    fileprivate static func from(cache: [String: Any], file: String) -> StyleViolation? {
        guard let severityString = (cache[LinterCache.Key.severity.rawValue] as? String),
            let severity = ViolationSeverity(rawValue: severityString),
            let name = cache[LinterCache.Key.type.rawValue] as? String,
            let ruleID = cache[LinterCache.Key.ruleID.rawValue] as? String,
            let reason = cache[LinterCache.Key.reason.rawValue] as? String else {
                return nil
        }

        let line = cache[LinterCache.Key.line.rawValue] as? Int
        let character = cache[LinterCache.Key.character.rawValue] as? Int

        let ruleDescription = RuleDescription(identifier: ruleID, name: name, description: reason)
        let location = Location(file: file, line: line, character: character)
        let violation = StyleViolation(ruleDescription: ruleDescription, severity: severity,
                                       location: location, reason: reason)

        return violation
    }
}
