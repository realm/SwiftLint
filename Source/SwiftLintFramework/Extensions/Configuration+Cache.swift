#if canImport(CryptoSwift)
import CryptoSwift
#endif
import Foundation

extension Configuration {
    // MARK: Caching Configurations By Identifier (In-Memory)
    private static var cachedConfigurationsByIdentifier = [String: Configuration]()
    private static var cachedConfigurationsByIdentifierLock = NSLock()

    /// Since the cache is stored in a static var, this function is used to reset the cache during tests
    internal static func resetCache() {
        Self.cachedConfigurationsByIdentifierLock.lock()
        Self.cachedConfigurationsByIdentifier = [:]
        Self.cachedConfigurationsByIdentifierLock.unlock()
    }

    internal func setCached(forIdentifier identifier: String) {
        Self.cachedConfigurationsByIdentifierLock.lock()
        Self.cachedConfigurationsByIdentifier[identifier] = self
        Self.cachedConfigurationsByIdentifierLock.unlock()
    }

    internal static func getCached(forIdentifier identifier: String) -> Configuration? {
        cachedConfigurationsByIdentifierLock.lock()
        defer { cachedConfigurationsByIdentifierLock.unlock() }
        return cachedConfigurationsByIdentifier[identifier]
    }

    /// Returns a copy of the current `Configuration` with its `computedCacheDescription` property set to the value of
    /// `cacheDescription`, which is expensive to compute.
    ///
    /// - returns: A new `Configuration` value.
    public func withPrecomputedCacheDescription() -> Configuration {
        var result = self
        result.computedCacheDescription = result.cacheDescription
        return result
    }

    // MARK: Nested Config Is Self Cache
    private static var nestedConfigIsSelfByIdentifier = [String: Bool]()
    private static var nestedConfigIsSelfByIdentifierLock = NSLock()

    internal static func setIsNestedConfigurationSelf(forIdentifier identifier: String, value: Bool) {
        Self.nestedConfigIsSelfByIdentifierLock.lock()
        Self.nestedConfigIsSelfByIdentifier[identifier] = value
        Self.nestedConfigIsSelfByIdentifierLock.unlock()
    }

    internal static func getIsNestedConfigurationSelf(forIdentifier identifier: String) -> Bool? {
        Self.nestedConfigIsSelfByIdentifierLock.lock()
        defer { Self.nestedConfigIsSelfByIdentifierLock.unlock() }
        return Self.nestedConfigIsSelfByIdentifier[identifier]
    }

    // MARK: SwiftLint Cache (On-Disk)
    internal var cacheDescription: String {
        if let computedCacheDescription {
            return computedCacheDescription
        }

        let cacheRulesDescriptions = rules
            .map { rule in [type(of: rule).description.identifier, rule.cacheDescription] }
            .sorted { $0[0] < $1[0] }
        let jsonObject: [Any] = [rootDirectory, cacheRulesDescriptions]
        if let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject) {
            return jsonData.sha256().toHexString()
        }
        queuedFatalError("Could not serialize configuration for cache")
    }

    internal var cacheURL: URL {
        let baseURL: URL
        if let path = cachePath {
            baseURL = URL(fileURLWithPath: path, isDirectory: true)
        } else {
#if os(Linux)
            baseURL = URL(fileURLWithPath: "/var/tmp/", isDirectory: true)
#else
            baseURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
#endif
        }

        let versionedDirectory = [
            "SwiftLint",
            Version.current.value,
            ExecutableInfo.buildID
        ].compactMap({ $0 }).joined(separator: "/")

        let folder = baseURL.appendingPathComponent(versionedDirectory)

        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)
        } catch {
            queuedPrintError("Error while creating cache: " + error.localizedDescription)
        }

        return folder
    }
}
