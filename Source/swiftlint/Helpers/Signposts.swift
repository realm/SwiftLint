#if canImport(os)
import os.signpost
private let timelineLog = OSLog(subsystem: "io.realm.swiftlint", category: "Timeline")
private let fileLog = OSLog(subsystem: "io.realm.swiftlint", category: "File")
#endif

struct Signposts {
    enum Span {
        case timeline, file(String)
    }

    static func record<R>(name: StaticString, span: Span = .timeline, body: () throws -> R) rethrows -> R {
#if canImport(os)
        let log: OSLog
        let description: String?
        switch span {
        case .timeline:
            log = timelineLog
            description = nil
        case .file(let file):
            log = fileLog
            description = file
        }
        let signpostID = OSSignpostID(log: log)
        if let description {
            os_signpost(.begin, log: log, name: name, signpostID: signpostID, "%{public}s", description)
        } else {
            os_signpost(.begin, log: log, name: name, signpostID: signpostID)
        }

        let result = try body()
        if let description {
            os_signpost(.end, log: log, name: name, signpostID: signpostID, "%{public}s", description)
        } else {
            os_signpost(.end, log: log, name: name, signpostID: signpostID)
        }
        return result
#else
        return try body()
#endif
    }

    static func record<R>(name: StaticString, span: Span = .timeline, body: () async throws -> R) async rethrows -> R {
#if canImport(os)
        let log: OSLog
        let description: String?
        switch span {
        case .timeline:
            log = timelineLog
            description = nil
        case .file(let file):
            log = fileLog
            description = file
        }
        let signpostID = OSSignpostID(log: log)
        if let description {
            os_signpost(.begin, log: log, name: name, signpostID: signpostID, "%{public}s", description)
        } else {
            os_signpost(.begin, log: log, name: name, signpostID: signpostID)
        }

        let result = try await body()
        if let description {
            os_signpost(.end, log: log, name: name, signpostID: signpostID, "%{public}s", description)
        } else {
            os_signpost(.end, log: log, name: name, signpostID: signpostID)
        }
        return result
#else
        return try await body()
#endif
    }
}
