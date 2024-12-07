#if !os(Linux)
import Network
#endif

/// Helper enum providing the static var `connectivityStatus`
enum Reachability {
    enum ConnectivityStatus {
        case connected, disconnected, unknown
    }

    /// Returns whether the device is connected to a network, if known.
    /// On Linux, this always evaluates to `nil`.
    static var connectivityStatus: ConnectivityStatus {
        get async {
            #if os(Linux)
            return .unknown
            #else
            return await withCheckedContinuation { continuation in
                let monitor = NWPathMonitor()
                let queue = DispatchQueue.global(qos: .background)
                monitor.pathUpdateHandler = { path in
                    if path.status == .satisfied {
                        continuation.resume(returning: .connected)
                    } else {
                        continuation.resume(returning: .disconnected)
                    }
                }
                monitor.start(queue: queue)
            }
            #endif
        }
    }
}
