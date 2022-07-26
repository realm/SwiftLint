#if canImport(CommonCrypto)
import CommonCrypto

extension String {
    internal func sha256() -> String {
        let theData = data(using: .utf8)!
        return theData.withUnsafeBytes { bytes in
            var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
            _ = CC_SHA256(bytes.baseAddress, CC_LONG(theData.count), &hash)
            return hash.reduce(into: "") { $0.append(String(format: "%02x", $1)) }
        }
    }
}
#endif
