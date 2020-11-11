#if canImport(CommonCrypto)
import CommonCrypto

extension String {
    internal func md5() -> String {
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
