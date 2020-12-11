import Dispatch
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#else
#error("Unsupported platform")
#endif

DispatchQueue.global().async {
    SwiftLint.mainHandlingDeprecatedCommands()
    exit(EXIT_SUCCESS)
}

dispatchMain()
