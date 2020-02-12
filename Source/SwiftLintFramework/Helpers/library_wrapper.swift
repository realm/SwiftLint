import Foundation

// MARK: - Shared Types & Functions

struct DynamicLinkLibrary {
    fileprivate let handle: UnsafeMutableRawPointer

    func load<T>(symbol: String) -> T {
        if let sym = dlsym(handle, symbol) {
            return unsafeBitCast(sym, to: T.self)
        }
        let errorString = String(validatingUTF8: dlerror())
        fatalError("Finding symbol \(symbol) failed: \(errorString ?? "unknown error")")
    }
}

struct Loader {
    let searchPaths: [String]

    func load(path: String) -> DynamicLinkLibrary {
        let fullPaths = searchPaths.map { $0.appending(pathComponent: path) }.filter { $0.isFile }

        // try all fullPaths that contains target file,
        // then try loading with simple path that depends resolving to DYLD
        for fullPath in fullPaths + [path] {
            if let handle = dlopen(fullPath, RTLD_LAZY) {
                return DynamicLinkLibrary(handle: handle)
            }
        }

        fatalError("Loading \(path) failed")
    }
}

private func env(_ name: String) -> String? {
    return ProcessInfo.processInfo.environment[name]
}

private extension String {
    func appending(pathComponent: String) -> String {
        return URL(fileURLWithPath: self).appendingPathComponent(pathComponent).path
    }

    func deleting(lastPathComponents numberOfPathComponents: Int) -> String {
        return (0..<numberOfPathComponents)
            .reduce(URL(fileURLWithPath: self)) { url, _ in url.deletingLastPathComponent() }
            .path
    }
}

#if os(Linux)

// MARK: - Linux

/// Returns "LINUX_SOURCEKIT_LIB_PATH" environment variable.
internal let linuxSourceKitLibPath = env("LINUX_SOURCEKIT_LIB_PATH")

/// If available, uses `swiftenv` to determine the user's active Swift root.
internal let linuxFindSwiftenvActiveLibPath: String? = {
    guard let swiftenvPath = Exec.run("/usr/bin/which", "swiftenv").string else {
        return nil
    }

    guard let swiftenvRoot = Exec.run(swiftenvPath, "prefix").string else {
        return nil
    }

    return swiftenvRoot + "/usr/lib"
}()

/// Attempts to discover the location of libsourcekitdInProc.so by looking at
/// the `swift` binary on the path.
internal let linuxFindSwiftInstallationLibPath: String? = {
    guard let swiftPath = Exec.run("/usr/bin/which", "swift").string else {
        return nil
    }

    if linuxSourceKitLibPath == nil && linuxFindSwiftenvActiveLibPath == nil &&
       swiftPath.hasSuffix("/shims/swift") {
        /// If we hit this path, the user is invoking Swift via swiftenv shims and has not set the
        /// environment variable; this means we're going to end up trying to load from `/usr/lib`
        /// which will fail - and instead, we can give a more useful error message.
        fatalError("Swift is installed via swiftenv but swiftenv is not initialized.")
    }

    if !swiftPath.hasSuffix("/bin/swift") {
        return nil
    }

    /// .../bin/swift -> .../lib
    return swiftPath.deleting(lastPathComponents: 2).appending(pathComponent: "/lib")
}()

/// Fallback path on Linux if no better option is available.
internal let linuxDefaultLibPath = "/usr/lib"

let toolchainLoader = Loader(searchPaths: [
    linuxSourceKitLibPath,
    linuxFindSwiftenvActiveLibPath,
    linuxFindSwiftInstallationLibPath,
    linuxDefaultLibPath
].compactMap({ $0 }))

#else

// MARK: - Darwin

let toolchainLoader = Loader(searchPaths: [
    xcodeDefaultToolchainOverride,
    toolchainDir,
    xcrunFindPath,
    /*
    These search paths are used when `xcode-select -p` points to
    "Command Line Tools OS X for Xcode", but Xcode.app exists.
    */
    applicationsDir?.xcodeDeveloperDir.toolchainDir,
    applicationsDir?.xcodeBetaDeveloperDir.toolchainDir,
    userApplicationsDir?.xcodeDeveloperDir.toolchainDir,
    userApplicationsDir?.xcodeBetaDeveloperDir.toolchainDir
].compactMap { path in
    if let fullPath = path?.usrLibDir, FileManager.default.fileExists(atPath: fullPath) {
        return fullPath
    }
    return nil
})

/// Returns "XCODE_DEFAULT_TOOLCHAIN_OVERRIDE" environment variable
///
/// `launch-with-toolchain` sets the toolchain path to the
/// "XCODE_DEFAULT_TOOLCHAIN_OVERRIDE" environment variable.
private let xcodeDefaultToolchainOverride = env("XCODE_DEFAULT_TOOLCHAIN_OVERRIDE")

/// Returns "TOOLCHAIN_DIR" environment variable
///
/// `Xcode`/`xcodebuild` sets the toolchain path to the
/// "TOOLCHAIN_DIR" environment variable.
private let toolchainDir = env("TOOLCHAIN_DIR")

/// Returns toolchain directory that parsed from result of `xcrun -find swift`
///
/// This is affected by "DEVELOPER_DIR", "TOOLCHAINS" environment variables.
private let xcrunFindPath: String? = {
    let pathOfXcrun = "/usr/bin/xcrun"

    if !FileManager.default.isExecutableFile(atPath: pathOfXcrun) {
        return nil
    }

    guard let output = Exec.run(pathOfXcrun, "-find", "swift").string else {
        return nil
    }

    var start = output.startIndex
    var end = output.startIndex
    var contentsEnd = output.startIndex
    output.getLineStart(&start, end: &end, contentsEnd: &contentsEnd, for: start..<start)
    let xcrunFindSwiftPath = String(output[start..<contentsEnd])
    guard xcrunFindSwiftPath.hasSuffix("/usr/bin/swift") else {
        return nil
    }
    let xcrunFindPath = xcrunFindSwiftPath.appending(pathComponent: "macosx")
    // Return nil if xcrunFindPath points to "Command Line Tools OS X for Xcode"
    // because it doesn't contain `sourcekitd.framework`.
    if xcrunFindPath.hasPrefix("/Library/Developer/CommandLineTools") {
        return nil
    }
    return xcrunFindPath
}()

private func appDir(mask: FileManager.SearchPathDomainMask) -> String? {
    return NSSearchPathForDirectoriesInDomains(.applicationDirectory, mask, true).first
}

private let applicationsDir = appDir(mask: .systemDomainMask)

private let userApplicationsDir = appDir(mask: .userDomainMask)

private extension String {
    var toolchainDir: String {
        return appending(pathComponent: "Toolchains/XcodeDefault.xctoolchain/")
    }

    var xcodeDeveloperDir: String {
        return appending(pathComponent: "Xcode.app/Contents/Developer")
    }

    var xcodeBetaDeveloperDir: String {
        return appending(pathComponent: "Xcode-beta.app/Contents/Developer")
    }

    var usrLibDir: String {
        return appending(pathComponent: "/usr/lib/swift")
    }
}
#endif
