#if os(Linux)
#if canImport(Glibc)
import func Glibc.exit
#elseif canImport(Musl)
import func Musl.exit
#endif
#endif

package enum ExitHelper {
    package static func successfullyExit() {
#if os(Linux)
        // Workaround for https://github.com/apple/swift/issues/59961
        exit(0)
#endif
    }
}
