#if canImport(CommonCrypto)
import CommonCrypto
#else
import CryptoSwift
#endif
import Foundation

#if canImport(CommonCrypto)
private extension String {
    func md5() -> String {
        let context = UnsafeMutablePointer<CC_MD5_CTX>.allocate(capacity: 1)
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        CC_MD5_Init(context)
        CC_MD5_Update(context, self, CC_LONG(lengthOfBytes(using: .utf8)))
        CC_MD5_Final(&digest, context)
        context.deallocate()
        return digest.reduce(into: "") { $0.append(String(format: "%02x", $1)) }
    }
}
#endif

extension Configuration {
    // MARK: Caching Configurations By Identifier (In-Memory)
    private static var cachedConfigurationsByIdentifier = [String: Configuration]()
    private static var cachedConfigurationsByIdentifierLock = NSLock()

    internal func setCached(forIdentifier identifier: String) {
        Configuration.cachedConfigurationsByIdentifierLock.lock()
        Configuration.cachedConfigurationsByIdentifier[identifier] = self
        Configuration.cachedConfigurationsByIdentifierLock.unlock()
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
        Configuration.nestedConfigIsSelfByIdentifierLock.lock()
        Configuration.nestedConfigIsSelfByIdentifier[identifier] = value
        Configuration.nestedConfigIsSelfByIdentifierLock.unlock()
    }

    internal static func getIsNestedConfigurationSelf(forIdentifier identifier: String) -> Bool? {
        Configuration.nestedConfigIsSelfByIdentifierLock.lock()
        defer { Configuration.nestedConfigIsSelfByIdentifierLock.unlock() }
        return Configuration.nestedConfigIsSelfByIdentifier[identifier]
    }

    // MARK: SwiftLint Cache (On-Disk)
    internal var cacheDescription: String {
        if let computedCacheDescription = computedCacheDescription {
            return computedCacheDescription
        }

        let cacheRulesDescriptions = rules
            .map { rule in [type(of: rule).description.identifier, rule.cacheDescription] }
            .sorted { $0[0] < $1[0] }
        let jsonObject: [Any] = [
            rootDirectory ?? FileManager.default.currentDirectoryPath.bridge().standardizingPath,
            cacheRulesDescriptions
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject),
            let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString.md5()
        }
        queuedFatalError("Could not serialize configuration for cache")
    }

    internal var cacheURL: URL {
        let baseURL: URL
        if let path = cachePath {
            baseURL = URL(fileURLWithPath: path)
        } else {
            #if os(Linux)
            baseURL = URL(fileURLWithPath: "/var/tmp/")
            #else
            baseURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            #endif
        }
        let folder = baseURL.appendingPathComponent("SwiftLint/\(Version.current.value)")

        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)
        } catch {
            queuedPrintError("Error while creating cache: " + error.localizedDescription)
        }

        return folder
    }
}
