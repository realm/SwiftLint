#if canImport(CommonCrypto)
import CommonCrypto
#else
import CryptoSwift
#endif
import Foundation
import SourceKittenFramework

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

/// Reports violations as a JSON array.
public struct CodeClimateReporter: Reporter {
    // MARK: - Reporter Conformance

    public static let identifier = "codeclimate"
    public static let isRealtime = false

    public var description: String {
        return "Reports violations as a JSON array in Code Climate format."
    }

    public static func generateReport(_ violations: [StyleViolation]) -> String {
        return toJSON(violations.map(dictionary(for:)))
            .replacingOccurrences(of: "\\/", with: "/")
    }

    // MARK: - Private

    private static func dictionary(for violation: StyleViolation) -> [String: Any] {
        return [
            "check_name": violation.ruleName,
            "description": violation.reason,
            "engine_name": "SwiftLint",
            "fingerprint": generateFingerprint(violation),
            "location": [
                "path": violation.location.file ?? NSNull() as Any,
                "lines": [
                    "begin": violation.location.line ?? NSNull() as Any,
                    "end": violation.location.line ?? NSNull() as Any
                ]
            ],
            "severity": violation.severity == .error ? "MAJOR": "MINOR",
            "type": "issue"
        ]
    }

    internal static func generateFingerprint(_ violation: StyleViolation) -> String {
        return [
            "\(violation.location)",
            "\(violation.ruleIdentifier)"
        ].joined().md5()
    }
}
