#if canImport(os)
import os.signpost
private let timelineLog = OSLog(subsystem: "io.realm.swiftlint", category: "Timeline")
private let fileLog = OSLog(subsystem: "io.realm.swiftlint", category: "File")
#endif

struct Signposts {
    enum Span {
        case timeline, file(String)
    }

    static func record<R>(name: StaticString, span: Span = .timeline, body: () -> R) -> R {
#if canImport(os)
        if #available(OSX 10.14, *) {
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
            if let description = description {
                os_signpost(.begin, log: log, name: name, signpostID: signpostID, "%{public}s", description)
            } else {
                os_signpost(.begin, log: log, name: name, signpostID: signpostID)
            }

            let result = body()
            if let description = description {
                os_signpost(.end, log: log, name: name, signpostID: signpostID, "%{public}s", description)
            } else {
                os_signpost(.end, log: log, name: name, signpostID: signpostID)
            }
            return result
        }
#endif
        return body()
    }
}
