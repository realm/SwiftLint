import Foundation

private typealias RuleId = String

private enum LinterCacheError: Error {
    case noLocation
}

private struct FileCacheEntry: Codable {
    var violations: [StyleViolation]
    var collectInfo: [RuleId: CollectCacheInfo]
    var lastModification: Date
    var swiftVersion: SwiftVersion

    static func empty(lastModification: Date, swiftVersion: SwiftVersion) -> FileCacheEntry {
        return FileCacheEntry(
            violations: [],
            collectInfo: [:],
            lastModification: lastModification,
            swiftVersion: swiftVersion
        )
    }
}

private struct CollectCacheInfo: Codable {
    let compilerArgumentsHash: String
    let dto: CollectingCacheDto
}

private struct FileCache: Codable {
    var entries: [String: FileCacheEntry]

    static var empty: FileCache { return FileCache(entries: [:]) }
}

/// A persisted cache for storing and retrieving linter results.
public final class LinterCache {
    private typealias Encoder = PropertyListEncoder
    private typealias Decoder = PropertyListDecoder
    private static let fileExtension = "plist"

    private typealias Cache = [String: FileCache]

    private var lazyReadCache: Cache
    private let readCacheLock = NSLock()
    private var writeCache = Cache()
    private let writeCacheLock = NSLock()
    internal let fileManager: LintableFileManager
    private let location: URL?
    private let swiftVersion: SwiftVersion

    internal init(fileManager: LintableFileManager = FileManager.default, swiftVersion: SwiftVersion = .current) {
        location = nil
        self.fileManager = fileManager
        self.lazyReadCache = Cache()
        self.swiftVersion = swiftVersion
    }

    /// Creates a `LinterCache` by specifying a SwiftLint configuration and a file manager.
    ///
    /// - parameter configuration: The SwiftLint configuration for which this cache will be used.
    /// - parameter fileManager:   The file manager to use to read lintable file information.
    public init(configuration: Configuration, fileManager: LintableFileManager = FileManager.default) {
        location = configuration.cacheURL
        lazyReadCache = Cache()
        self.fileManager = fileManager
        self.swiftVersion = .current
    }

    private init(cache: Cache, location: URL?, fileManager: LintableFileManager, swiftVersion: SwiftVersion) {
        self.lazyReadCache = cache
        self.location = location
        self.fileManager = fileManager
        self.swiftVersion = swiftVersion
    }

    internal func cache(violations: [StyleViolation], forFile file: String, configuration: Configuration) {
        update(violations: violations, file: file, configuration: configuration)
    }

    internal func cache<R: CollectingRule>(
        collectFileInfo: R.FileInfo,
        compilerArguments: [String],
        rule: R.Type,
        forFile file: String,
        configuration: Configuration
    ) where R.FileInfo: CollectingCacheable {
        update(
            collectInfo: (
                R.description.identifier,
                CollectCacheInfo(
                    compilerArgumentsHash: compilerArguments.hash(),
                    dto: collectFileInfo.toDto()
                )
            ),
            file: file,
            configuration: configuration
        )
    }

    private func update(
        violations: [StyleViolation]? = nil,
        collectInfo: (RuleId, CollectCacheInfo)? = nil,
        file: String,
        configuration: Configuration
    ) {
        guard let lastModification = fileManager.modificationDate(forFileAtPath: file) else {
            queuedPrintError(
                "Unexpected error for file '\(file)': could not obtain the last modification date while saving to cache"
            )
            return
        }

        let configurationDescription = configuration.cacheDescription

        writeCacheLock.lock()
        var filesCache = writeCache[configurationDescription] ?? .empty
        var fileEntry = filesCache.entries[file] ?? .empty(
            lastModification: lastModification,
            swiftVersion: swiftVersion
        )

        if let violations = violations {
            fileEntry.violations = violations
        }
        if let (ruleId, collectInfo) = collectInfo {
            fileEntry.collectInfo[ruleId] = collectInfo
        }

        filesCache.entries[file] = fileEntry
        writeCache[configurationDescription] = filesCache
        writeCacheLock.unlock()
    }

    internal func violations(forFile file: String, configuration: Configuration) -> [StyleViolation]? {
        guard let entry = getEntry(forFile: file, configuration: configuration) else {
            return nil
        }

        return entry.violations
    }

    internal func collectedFileInfo<R: CollectingRule>(
        for rule: R.Type,
        forFile file: String,
        compilerArguments: [String],
        configuration: Configuration
    ) -> R.FileInfo? where R.FileInfo: CollectingCacheable {
        guard let entry = getEntry(forFile: file, configuration: configuration),
              let collectInfo = entry.collectInfo[R.description.identifier],
              collectInfo.compilerArgumentsHash == compilerArguments.hash() else {
            return nil
        }

        return R.FileInfo.fromDto(collectInfo.dto)
    }

    private func getEntry(forFile file: String, configuration: Configuration) -> FileCacheEntry? {
        guard let lastModification = fileManager.modificationDate(forFileAtPath: file),
            let entry = fileCache(cacheDescription: configuration.cacheDescription).entries[file],
            entry.lastModification == lastModification,
            entry.swiftVersion == swiftVersion
        else {
            return nil
        }

        return entry
    }

    /// Persists the cache to disk.
    ///
    /// - throws: Throws if the linter cache doesn't have a `location` value, if the cache couldn't be serialized, or if
    ///           the contents couldn't be written to disk.
    public func save() throws {
        guard let url = location else {
            throw LinterCacheError.noLocation
        }
        writeCacheLock.lock()
        defer {
            writeCacheLock.unlock()
        }
        guard writeCache.isNotEmpty else {
            return
        }

        readCacheLock.lock()
        let readCache = lazyReadCache
        readCacheLock.unlock()

        let encoder = Encoder()
        for (description, writeFileCache) in writeCache where writeFileCache.entries.isNotEmpty {
            let fileCacheEntries = readCache[description]?.entries.merging(writeFileCache.entries) { _, write in write }
            let fileCache = fileCacheEntries.map(FileCache.init) ?? writeFileCache
            let data = try encoder.encode(fileCache)
            let file = url.appendingPathComponent(description).appendingPathExtension(Self.fileExtension)
            try data.write(to: file, options: .atomic)
        }
    }

    internal func flushed() -> LinterCache {
        return LinterCache(cache: mergeCaches(), location: location, fileManager: fileManager,
                           swiftVersion: swiftVersion)
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
            return .empty
        }

        let file = location.appendingPathComponent(cacheDescription).appendingPathExtension(Self.fileExtension)
        let data = try? Data(contentsOf: file)
        let fileCache = data.flatMap { try? Decoder().decode(FileCache.self, from: $0) } ?? .empty
        lazyReadCache[cacheDescription] = fileCache
        return fileCache
    }

    private func mergeCaches() -> Cache {
        readCacheLock.lock()
        writeCacheLock.lock()
        defer {
            readCacheLock.unlock()
            writeCacheLock.unlock()
        }
        return lazyReadCache.merging(writeCache) { read, write in
            FileCache(entries: read.entries.merging(write.entries) { _, write in write })
        }
    }
}

private extension Array where Element == String {
    func hash() -> String {
        return self.joined(separator: " ").md5()
    }
}
