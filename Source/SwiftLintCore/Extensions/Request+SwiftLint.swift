import Foundation
import SourceKittenFramework

public extension Request {
    static let disableSourceKit = ProcessInfo.processInfo.environment["SWIFTLINT_DISABLE_SOURCEKIT"] != nil

    func sendIfNotDisabled() throws -> [String: SourceKitRepresentable] {
        guard !Self.disableSourceKit else {
            throw Self.Error.connectionInterrupted("SourceKit is disabled by `SWIFTLINT_DISABLE_SOURCEKIT`.")
        }
        return try send()
    }
}
