#if os(Linux)
import Glibc
#endif

package enum ExitHelper {
    package static func successfullyExit() {
#if os(Linux)
        // Workaround for https://github.com/apple/swift/issues/59961
        Glibc.exit(0)
#endif
    }
}
