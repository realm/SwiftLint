#if canImport(CryptoKit)
import CryptoKit
#elseif canImport(Crypto)
import Crypto
#endif

import Foundation

extension Data {
    internal func sha256() -> Data {
        Data(SHA256.hash(data: self))
    }

    internal func toHexString() -> String {
        reduce(into: "") { $0.append(String(format: "%02x", $1)) }
    }
}

extension String {
    internal func sha256() -> String {
        Data(utf8).sha256().toHexString()
    }
}
