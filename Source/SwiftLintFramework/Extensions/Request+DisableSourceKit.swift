import Foundation
import SourceKittenFramework

extension Request {
    static let disableSourceKit = ProcessInfo.processInfo.environment["SWIFTLINT_DISABLE_SOURCEKIT"] != nil

    func sendIfNotDisabled() throws -> [String: SourceKitRepresentable] {
        guard !Request.disableSourceKit else {
            throw Request.Error.connectionInterrupted("SourceKit is disabled by `SWIFTLINT_DISABLE_SOURCEKIT`.")
        }
        return try send()
    }
}
