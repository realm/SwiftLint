import Foundation
import SourceKittenFramework
@testable import SwiftLintFramework
import XCTest

let config: Configuration = {
    let directory = #file.bridge()
        .deletingLastPathComponent.bridge()
        .deletingLastPathComponent.bridge()
        .deletingLastPathComponent
    _ = FileManager.default.changeCurrentDirectoryPath(directory)
    return Configuration(path: Configuration.fileName)
}()

class IntegrationTests: XCTestCase {
    func testSwiftLintLints() {
        // This is as close as we're ever going to get to a self-hosting linter.
        let swiftFiles = config.lintableFiles(inPath: "", forceExclude: false)
        XCTAssert(swiftFiles.map({ $0.path! }).contains(#file), "current file should be included")

        let violations = swiftFiles.parallelFlatMap {
            Linter(file: $0, configuration: config).styleViolations
        }
        violations.forEach { violation in
            violation.location.file!.withStaticString {
                XCTFail(violation.reason, file: $0, line: UInt(violation.location.line!))
            }
        }
    }

    func testSwiftLintAutoCorrects() {
        let swiftFiles = config.lintableFiles(inPath: "", forceExclude: false)
        let corrections = swiftFiles.parallelFlatMap { Linter(file: $0, configuration: config).correct() }
        for correction in corrections {
            correction.location.file!.withStaticString {
                XCTFail(correction.ruleDescription.description,
                        file: $0, line: UInt(correction.location.line!))
            }
        }
    }

    func testSimulateHomebrewTest() {
        // Since this test uses the `swiftlint` binary built while building `SwiftLintPackageTests`,
        // we run it only on macOS using SwiftPM.
#if os(macOS) && SWIFT_PACKAGE
        guard let swiftlintURL = swiftlintBuiltBySwiftPM(),
            let (testSwiftURL, seatbeltURL) = prepareSandbox() else {
            return
        }

        defer {
            try? FileManager.default.removeItem(at: testSwiftURL.deletingLastPathComponent())
            try? FileManager.default.removeItem(at: seatbeltURL)
        }

        let swiftlintInSandboxArgs = ["sandbox-exec", "-f", seatbeltURL.path, "sh", "-c",
                                      "SWIFTLINT_SWIFT_VERSION=3 \(swiftlintURL.path) --no-cache"]
        let swiftlintResult = execute(swiftlintInSandboxArgs, in: testSwiftURL.deletingLastPathComponent())
        if #available(macOS 10.14.1, *) {
            // Within a sandbox on macOS 10.14.1+, `swiftlint` crashes with "Test::Unit::AssertionFailedError"
            // error in `libxpc.dylib` when calling `sourcekitd_send_request_sync`.
            //
            // Since Homebrew CI succeeded in bottling swiftlint 0.27.0 on release of macOS 10.14,
            // `swiftlint` may not crash on macOS 10.14. But that is not confirmed.
            XCTAssertEqual(swiftlintResult.status, 11, "It is expected to crash.")
            XCTAssertEqual(swiftlintResult.stdout, "")
            XCTAssertEqual(swiftlintResult.stderr, """
                Linting Swift files at paths \n\
                Linting 'Test.swift' (1/1)

                """)
        } else {
            XCTAssertEqual(swiftlintResult.status, 0)
            XCTAssertEqual(swiftlintResult.stdout, """
                \(testSwiftURL.path):1: \
                warning: Trailing Newline Violation: Files should have a single trailing newline. (trailing_newline)

                """)
            XCTAssertEqual(swiftlintResult.stderr, """
                Linting Swift files at paths \n\
                Linting 'Test.swift' (1/1)
                Connection invalid
                Most rules will be skipped because sourcekitd has failed.
                Done linting! Found 1 violation, 0 serious in 1 file.

                """)
        }
#endif
    }

    func testSimulateHomebrewTestWithDisableSourceKit() {
        // Since this test uses the `swiftlint` binary built while building `SwiftLintPackageTests`,
        // we run it only on macOS using SwiftPM.
#if os(macOS) && SWIFT_PACKAGE
        guard let swiftlintURL = swiftlintBuiltBySwiftPM(),
            let (testSwiftURL, seatbeltURL) = prepareSandbox() else {
                return
        }

        defer {
            try? FileManager.default.removeItem(at: testSwiftURL.deletingLastPathComponent())
            try? FileManager.default.removeItem(at: seatbeltURL)
        }

        let swiftlintInSandboxArgs = [
            "sandbox-exec", "-f", seatbeltURL.path, "sh", "-c",
            "SWIFTLINT_SWIFT_VERSION=3 SWIFTLINT_DISABLE_SOURCEKIT=1 \(swiftlintURL.path) --no-cache"
        ]
        let swiftlintResult = execute(swiftlintInSandboxArgs, in: testSwiftURL.deletingLastPathComponent())
        XCTAssertEqual(swiftlintResult.status, 0)
        XCTAssertEqual(swiftlintResult.stdout, """
            \(testSwiftURL.path):1: \
            warning: Trailing Newline Violation: Files should have a single trailing newline. (trailing_newline)

            """)
        XCTAssertEqual(swiftlintResult.stderr, """
            Linting Swift files at paths \n\
            Linting 'Test.swift' (1/1)
            SourceKit is disabled by `SWIFTLINT_DISABLE_SOURCEKIT`.
            Most rules will be skipped because sourcekitd has failed.
            Done linting! Found 1 violation, 0 serious in 1 file.

            """)
#endif
    }
}

extension String {
    func withStaticString(_ closure: (StaticString) -> Void) {
        withCString {
            let rawPointer = $0._rawValue
            let byteSize = lengthOfBytes(using: .utf8)._builtinWordValue
            let isASCII = true._getBuiltinLogicValue()
            let staticString = StaticString(_builtinStringLiteral: rawPointer,
                                            utf8CodeUnitCount: byteSize,
                                            isASCII: isASCII)
            closure(staticString)
        }
    }
}

#if os(macOS) && SWIFT_PACKAGE

private func execute(_ args: [String],
                     in directory: URL? = nil,
                     input: Data? = nil) -> (status: Int32, stdout: String, stderr: String) {
    // swiftlint:disable:previous large_tuple
    let process = Process()
    process.launchPath = "/usr/bin/env"
    process.arguments = args
    if let directory = directory {
        process.currentDirectoryPath = directory.path
    }
    var environment = ProcessInfo.processInfo.environment
    environment["DISCORD_TOKEN"] = nil
    environment["DYNO"] = nil
    environment["PORT"] = nil
    environment["TIMEOUT"] = nil
    process.environment = environment
    let stdoutPipe = Pipe(), stderrPipe = Pipe()
    process.standardOutput = stdoutPipe
    process.standardError = stderrPipe
    if let input = input {
        let stdinPipe = Pipe()
        process.standardInput = stdinPipe.fileHandleForReading
        stdinPipe.fileHandleForWriting.write(input)
        stdinPipe.fileHandleForWriting.closeFile()
    }
    let group = DispatchGroup(), queue = DispatchQueue.global()
    var stdoutData: Data?, stderrData: Data?
    process.launch()
    queue.async(group: group) { stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile() }
    queue.async(group: group) { stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile() }
    process.waitUntilExit()
    group.wait()
    let stdout = stdoutData.flatMap { String(data: $0, encoding: .utf8) } ?? ""
    let stderr = stderrData.flatMap { String(data: $0, encoding: .utf8) } ?? ""
    return (process.terminationStatus, stdout, stderr)
}

private func prepareSandbox() -> (testSwiftURL: URL, seatbeltURL: URL)? {
    // Since `/private/tmp` is hard coded in `/usr/local/Homebrew/Library/Homebrew/sandbox.rb`, we use them.
    //    /private/tmp
    //    ├── AADA6B05-2E06-4E7F-BA48-8B3AF44415E3
    //    │   └── Test.swift
    //    ├── AADA6B05-2E06-4E7F-BA48-8B3AF44415E3.sb
    do {
        // `/private/tmp` is standardized to `/tmp` that is symbolic link to `/private/tmp`.
        let temporaryDirectoryURL = URL(fileURLWithPath: "/tmp").appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: temporaryDirectoryURL, withIntermediateDirectories: true)

        let seatbeltURL = temporaryDirectoryURL.appendingPathExtension("sb")
        try sandboxProfile().write(to: seatbeltURL, atomically: true, encoding: .utf8)

        let testSwiftURL = temporaryDirectoryURL.appendingPathComponent("Test.swift")
        try "import Foundation".write(to: testSwiftURL, atomically: true, encoding: .utf8)
        return (testSwiftURL, seatbeltURL)
    } catch {
        XCTFail("\(error)")
        return nil
    }
}

private func sandboxProfile() -> String {
    let homeDirectory = NSHomeDirectory()
    return """
        (version 1)
        (debug deny) ; log all denied operations to /var/log/system.log
        (allow file-write* (subpath "/private/tmp"))
        (allow file-write* (subpath "/private/var/tmp"))
        (allow file-write* (regex #"^/private/var/folders/[^/]+/[^/]+/[C,T]/"))
        (allow file-write* (subpath "/private/tmp"))
        (allow file-write* (subpath "\(homeDirectory)/Library/Caches/Homebrew"))
        (allow file-write* (subpath "\(homeDirectory)/Library/Logs/Homebrew/swiftlint"))
        (allow file-write* (subpath "\(homeDirectory)/Library/Developer"))
        (allow file-write* (subpath "/usr/local/var/cache"))
        (allow file-write* (subpath "/usr/local/var/homebrew/locks"))
        (allow file-write* (subpath "/usr/local/var/log"))
        (allow file-write* (subpath "/usr/local/var/run"))
        (allow file-write*
            (literal "/dev/ptmx")
            (literal "/dev/dtracehelper")
            (literal "/dev/null")
            (literal "/dev/random")
            (literal "/dev/zero")
            (regex #"^/dev/fd/[0-9]+$")
            (regex #"^/dev/ttys?[0-9]*$")
            )
        (deny file-write*) ; deny non-whitelist file write operations
        (allow process-exec
            (literal "/bin/ps")
            (with no-sandbox)
            ) ; allow certain processes running without sandbox
        (allow default) ; allow everything else

        """
}

private func swiftlintBuiltBySwiftPM() -> URL? {
#if DEBUG
    let configuration = "debug"
#else
    let configuration = "release"
#endif
    let swiftBuildShowBinPathArgs = ["swift", "build", "--show-bin-path", "--configuration", configuration]
    let binPathResult = execute(swiftBuildShowBinPathArgs)
    guard binPathResult.status == 0 else {
        let commandline = swiftBuildShowBinPathArgs.joined(separator: " ")
        XCTFail("`\(commandline)` failed with status: \(binPathResult.status), error: \(binPathResult.stderr)")
        return nil
    }
    let binPathString = binPathResult.stdout.components(separatedBy: CharacterSet.newlines).first!
    let swiftlint = URL(fileURLWithPath: binPathString).appendingPathComponent("swiftlint")
    guard FileManager.default.fileExists(atPath: swiftlint.path) else {
        XCTFail("`swiftlint` does not exists.")
        return nil
    }
    return swiftlint
}

#endif
