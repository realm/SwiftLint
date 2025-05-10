#if canImport(CommonCrypto)
import CommonCrypto
import Foundation

extension Data {
    internal func sha256() -> Data {
        withUnsafeBytes { bytes in
            var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
            _ = CC_SHA256(bytes.baseAddress, CC_LONG(count), &hash)
            return Data(hash)
        }
    }

    internal func toHexString() -> String {
        reduce(into: "") { $0.append(String(format: "%02x", $1)) }
    }
}

extension String {
    internal func sha256() -> String {
        data(using: .utf8)!.sha256().toHexString()
    }
}
#endif
