#if !os(Linux)
import SystemConfiguration
#endif

/// Helper class providing the static helper method `isConnectedToNetwork()`
internal class Reachability {
    enum ConnectivityStatus {
        case connected, disconnected, unknown
    }

    /// Returns whether the device is connected to a network, if known.
    /// On Linux, this always evaluates to `nil`.
    internal static var connectivityStatus: ConnectivityStatus {
#if os(Linux)
        return .unknown
#else
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)

        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return .unknown
        }

        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return .unknown
        }

        if flags.isEmpty {
            return .disconnected
        }

        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)

        return (isReachable && !needsConnection) ? .connected : .disconnected
#endif
    }
}
