import Foundation
#if os(macOS)
import Darwin.C
#else
import Glibc
#endif

/// A named unit of work that prints a message, runs the work and terminates the message with the time it took
/// to execute.
///
/// - parameter name: The step's name, printed before executing the work.
/// - parameter work: The work closure to execute and time.
///
/// - throws: Rethrows error thrown by the `work` closure.
///
/// - returns: The result of the `work` closure.
func TimedStep<Output>(_ name: String, work: () throws -> Output) rethrows -> Output {
    // swiftlint:disable:previous identifier_name - This looks better capitalized like a type name
    let start = Date()
    print(name, terminator: "")
    fflush(stdout)

    defer {
        let duration = String(format: "%.2fs", -start.timeIntervalSinceNow)
        print(" (\(duration))")
    }

    return try work()
}

func TimedStep<Output>(_ name: String, work: () async throws -> Output) async rethrows -> Output {
    // swiftlint:disable:previous identifier_name - This looks better capitalized like a type name
    let start = Date()
    print(name, terminator: "")
    fflush(stdout)

    defer {
        let duration = String(format: "%.2fs", -start.timeIntervalSinceNow)
        print(" (\(duration))")
    }

    return try await work()
}
