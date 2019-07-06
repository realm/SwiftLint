import Foundation

internal enum LinterCacheError: Error {
    case invalidFormat
    case noLocation
}

public final class LinterCache {
    private typealias FileCache = [String: [String: Any]]
    private typealias Cache = [String: FileCache]

    private var lazyReadCache: Cache
    private let readCacheLock = NSLock()
    private var writeCache = Cache()
    private let writeCacheLock = NSLock()
    internal let fileManager: LintableFileManager
    private let location: URL?
    private let swiftVersion: SwiftVersion

    internal init(fileManager: LintableFileManager = FileManager.default,
                  swiftVersion: SwiftVersion = .current) {
        location = nil
        self.fileManager = fileManager
        self.lazyReadCache = [:]
        self.swiftVersion = swiftVersion
    }

    internal init(cache: Any, fileManager: LintableFileManager = FileManager.default,
                  swiftVersion: SwiftVersion = .current) throws {
        guard let dictionary = cache as? Cache else {
            throw LinterCacheError.invalidFormat
        }

        self.lazyReadCache = dictionary
        location = nil
        self.fileManager = fileManager
        self.swiftVersion = swiftVersion
    }

    public init(configuration: Configuration,
                fileManager: LintableFileManager = FileManager.default) {
        location = configuration.cacheURL
        lazyReadCache = [:]
        self.fileManager = fileManager
        self.swiftVersion = .current
    }

    private init(cache: Cache, location: URL?, fileManager: LintableFileManager,
                 swiftVersion: SwiftVersion) {
        self.lazyReadCache = cache
        self.location = location
        self.fileManager = fileManager
        self.swiftVersion = swiftVersion
    }

    internal func cache(violations: [StyleViolation], forFile file: String, configuration: Configuration) {
        guard let lastModification = fileManager.modificationDate(forFileAtPath: file) else {
            return
        }

        let configurationDescription = configuration.cacheDescription

        writeCacheLock.lock()
        var filesCache = writeCache[configurationDescription] ?? [:]
        filesCache[file] = [
            Key.violations.rawValue: violations.map(dictionary(for:)),
            Key.lastModification.rawValue: lastModification.timeIntervalSinceReferenceDate,
            Key.swiftVersion.rawValue: swiftVersion.rawValue
        ]
        writeCache[configurationDescription] = filesCache
        writeCacheLock.unlock()
    }

    internal func violations(forFile file: String, configuration: Configuration) -> [StyleViolation]? {
        guard let lastModification = fileManager.modificationDate(forFileAtPath: file) else {
            return nil
        }

        let configurationDescription = configuration.cacheDescription

        func getCacheLastModification(dict: [String: Any]) -> TimeInterval? {
            let value = dict[.lastModification]
#if os(Linux)
            if let cacheLastModificationInt = value as? Int {
                return TimeInterval(cacheLastModificationInt)
            }
#endif
            return value as? TimeInterval
        }

        let filesCache = fileCache(cacheDescription: configurationDescription)
        guard let entry = filesCache[file],
            let cacheLastModification = getCacheLastModification(dict: entry),
            cacheLastModification == lastModification.timeIntervalSinceReferenceDate,
            let swiftVersion = (entry[.swiftVersion] as? String).flatMap(SwiftVersion.init(rawValue:)),
            swiftVersion == self.swiftVersion,
            let violations = entry[.violations] as? [[String: Any]]
        else {
            return nil
        }

        return violations.compactMap { StyleViolation.from(cache: $0, file: file) }
    }

    public func save() throws {
        guard let url = location else {
            throw LinterCacheError.noLocation
        }
        writeCacheLock.lock()
        defer {
            writeCacheLock.unlock()
        }
        guard !writeCache.isEmpty else {
            return
        }

        readCacheLock.lock()
        let readCache = lazyReadCache
        readCacheLock.unlock()

        for (description, writeFileCache) in writeCache {
            guard !writeFileCache.isEmpty else {
                continue
            }

            let fileCache = readCache[description]?.merging(writeFileCache) { _, write in write } ?? writeFileCache
            let json = try fileCache.toJSON()
            let file = url.appendingPathComponent(description).appendingPathExtension("json")
            try json.write(to: file, options: .atomic)
        }
    }

    internal func flushed() -> LinterCache {
        return LinterCache(cache: mergeCaches(), location: location,
                           fileManager: fileManager, swiftVersion: swiftVersion)
    }

    private func fileCache(cacheDescription: String) -> FileCache {
        readCacheLock.lock()
        defer {
            readCacheLock.unlock()
        }
        if let fileCache = lazyReadCache[cacheDescription] {
            return fileCache
        }

        guard let location = location else {
            return [:]
        }

        let file = location.appendingPathComponent(cacheDescription).appendingPathExtension("json")
        if let data = try? Data(contentsOf: file),
            let json = try? JSONSerialization.jsonObject(with: data),
            let fileCache = json as? FileCache {
            lazyReadCache[cacheDescription] = fileCache
            return fileCache
        } else {
            lazyReadCache[cacheDescription] = [:]
            return [:]
        }
    }

    private func mergeCaches() -> Cache {
        readCacheLock.lock()
        var cache = lazyReadCache
        readCacheLock.unlock()
        writeCacheLock.lock()
        for (key, value) in writeCache {
            var filesCache = cache[key] ?? [:]
            for (file, fileCache) in value {
                filesCache[file] = fileCache
            }
            cache[key] = filesCache
        }
        writeCacheLock.unlock()

        return cache
    }

    private func dictionary(for violation: StyleViolation) -> [String: Any] {
        return [
            Key.line.rawValue: violation.location.line ?? NSNull() as Any,
            Key.character.rawValue: violation.location.character ?? NSNull() as Any,
            Key.severity.rawValue: violation.severity.rawValue,
            Key.type.rawValue: violation.ruleDescription.name,
            Key.ruleID.rawValue: violation.ruleDescription.identifier,
            Key.reason.rawValue: violation.reason,
            Key.ruleKind.rawValue: violation.ruleDescription.kind.rawValue
        ]
    }
}

private extension LinterCache {
    enum Key: String {
        case character
        case lastModification = "last_modification"
        case line
        case reason
        case ruleID = "rule_id"
        case severity
        case type
        case violations
        case ruleKind = "rule_kind"
        case swiftVersion = "swift_version"
    }
}

private extension Dictionary where Key == String {
    subscript(_ key: LinterCache.Key) -> Value? {
        return self[key.rawValue]
    }
}

private extension StyleViolation {
    static func from(cache: [String: Any], file: String) -> StyleViolation? {
        guard let severityString = cache[.severity] as? String,
            let severity = ViolationSeverity(rawValue: severityString),
            let name = cache[.type] as? String,
            let ruleID = cache[.ruleID] as? String,
            let reason = cache[.reason] as? String,
            let ruleKind = (cache[.ruleKind] as? String).flatMap(RuleKind.init(rawValue:)) else {
                return nil
        }

        let line = cache[.line] as? Int
        let character = cache[.character] as? Int
        let description = RuleDescription(identifier: ruleID, name: name, description: reason, kind: ruleKind)
        return StyleViolation(ruleDescription: description,
                              severity: severity,
                              location: Location(file: file, line: line, character: character),
                              reason: reason)
    }
}

internal extension Dictionary where Key == String {
    func toJSON() throws -> Data {
        // not using .sortedKeys to avoid crash
        return try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
    }
}
