import Foundation

private enum LinterCacheError: Error {
    case invalidFormat
    case noLocation
}

private struct FileCacheEntry: Codable {
    let violations: [StyleViolation]
    let lastModification: Date
    let swiftVersion: SwiftVersion
}

private struct FileCache: Codable {
    var entries: [String: FileCacheEntry]

    static var empty: FileCache { return FileCache(entries: [:]) }
}

public final class LinterCache {
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
        guard let lastModification = fileManager.modificationDate(forFileAtPath: file) else {
            return
        }

        let configurationDescription = configuration.cacheDescription

        writeCacheLock.lock()
        var filesCache = writeCache[configurationDescription] ?? .empty
        filesCache.entries[file] = FileCacheEntry(violations: violations, lastModification: lastModification,
                                                  swiftVersion: swiftVersion)
        writeCache[configurationDescription] = filesCache
        writeCacheLock.unlock()
    }

    internal func violations(forFile file: String, configuration: Configuration) -> [StyleViolation]? {
        guard let lastModification = fileManager.modificationDate(forFileAtPath: file),
            let entry = fileCache(cacheDescription: configuration.cacheDescription).entries[file],
            entry.lastModification == lastModification,
            entry.swiftVersion == swiftVersion
        else {
            return nil
        }

        return entry.violations
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

        let encoder = PropertyListEncoder()
        for (description, writeFileCache) in writeCache where !writeFileCache.entries.isEmpty {
            let fileCacheEntries = readCache[description]?.entries.merging(writeFileCache.entries) { _, write in write }
            let fileCache = fileCacheEntries.map(FileCache.init) ?? writeFileCache
            let plist = try encoder.encode(fileCache)
            let file = url.appendingPathComponent(description).appendingPathExtension("plist")
            try plist.write(to: file, options: .atomic)
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

        let decoder = PropertyListDecoder()
        let file = location.appendingPathComponent(cacheDescription).appendingPathExtension("plist")
        let data = try? Data(contentsOf: file)
        let fileCache = data.flatMap { try? decoder.decode(FileCache.self, from: $0) } ?? .empty
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
