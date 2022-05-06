import Foundation
import SourceKittenFramework

extension Request {
    static let disableSourceKit = ProcessInfo.processInfo.environment["SWIFTLINT_DISABLE_SOURCEKIT"] != nil

    func sendIfNotDisabled() throws -> [String: SourceKitRepresentable] {
        guard !Self.disableSourceKit else {
            throw Self.Error.connectionInterrupted("SourceKit is disabled by `SWIFTLINT_DISABLE_SOURCEKIT`.")
        }
        return try send()
    }

    static func cursorInfo(file: String, offset: ByteCount, arguments: [String]) -> Request {
        .customRequest(request: [
            "key.request": UID("source.request.cursorinfo"),
            "key.name": file,
            "key.sourcefile": file,
            "key.offset": Int64(offset.value),
            "key.compilerargs": arguments,
            "key.cancel_on_subsequent_request": 0,
            "key.retrieve_symbol_graph": 0
        ])
    }
}
