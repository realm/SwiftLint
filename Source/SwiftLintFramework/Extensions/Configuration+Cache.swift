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
    // MARK: Caching Configurations By Path (In-Memory)

    private static var cachedConfigurationsByPath = [String: Configuration]()
    private static var cachedConfigurationsByPathLock = NSLock()

    internal func setCached(atPath path: String) {
        Configuration.cachedConfigurationsByPathLock.lock()
        Configuration.cachedConfigurationsByPath[path] = self
        Configuration.cachedConfigurationsByPathLock.unlock()
    }

    internal static func getCached(atPath path: String) -> Configuration? {
        cachedConfigurationsByPathLock.lock()
        defer { cachedConfigurationsByPathLock.unlock() }
        return cachedConfigurationsByPath[path]
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

    // MARK: SwiftLint Cache (On-Disk)

    internal var cacheDescription: String {
        if let computedCacheDescription = computedCacheDescription {
            return computedCacheDescription
        }

        let cacheRulesDescriptions = rules
            .map { rule in
                return [type(of: rule).description.identifier, rule.cacheDescription]
            }
            .sorted { rule1, rule2 in
                return rule1[0] < rule2[0]
            }
        let jsonObject: [Any] = [
            rootPath ?? FileManager.default.currentDirectoryPath,
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
