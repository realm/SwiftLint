import Foundation
import SourceKittenFramework

extension File {
    /// Extracts compiler arguments for this file from the specified compiler logs.
    ///
    /// - parameter compilerLogs: xcodebuild log output from a clean & successful build (not incremental).
    ///
    /// - returns: The compiler arguments for this file, or an empty array if none were found.
    func compilerArguments(compilerLogs: String) -> [String] {
        return path.flatMap { path in
            return compileCommand(compilerLogs: compilerLogs, sourceFile: path)
        } ?? []
    }
}

// MARK: - Private

#if os(Linux)
private extension Scanner {
    func scanString(string: String) -> String? {
        return scanString(string)
    }
}
#else
private extension Scanner {
    func scanUpToString(_ string: String) -> String? {
        var result: NSString?
        let success = scanUpTo(string, into: &result)
        if success {
            return result?.bridge()
        }
        return nil
    }

    func scanString(string: String) -> String? {
        var result: NSString?
        let success = scanString(string, into: &result)
        if success {
            return result?.bridge()
        }
        return nil
    }
}
#endif

private func compileCommand(compilerLogs: String, sourceFile: String) -> [String]? {
    let escapedSourceFile = sourceFile.replacingOccurrences(of: " ", with: "\\ ")
    guard compilerLogs.contains(escapedSourceFile) else {
        return nil
    }

    var compileCommand: [String]?
    compilerLogs.enumerateLines { line, stop in
        if line.contains(escapedSourceFile),
            let swiftcIndex = line.range(of: "swiftc ")?.upperBound,
            line.contains(" -module-name ") {
            compileCommand = parseCLIArguments(String(line[swiftcIndex...]))
            stop = true
        }
    }

    return compileCommand
}

private func parseCLIArguments(_ string: String) -> [String] {
    let escapedSpacePlaceholder = "\u{0}"
    let scanner = Scanner(string: string)
    var str = ""
    var didStart = false
    while let result = scanner.scanUpToString("\"") {
        if didStart {
            str += result.replacingOccurrences(of: " ", with: escapedSpacePlaceholder)
            str += " "
        } else {
            str += result
        }
        _ = scanner.scanString(string: "\"")
        didStart = !didStart
    }
    return filter(arguments:
        str.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "\\ ", with: escapedSpacePlaceholder)
            .components(separatedBy: " ")
            .map { $0.replacingOccurrences(of: escapedSpacePlaceholder, with: " ") }
    )
}

/**
 Partially filters compiler arguments from `xcodebuild` to something that SourceKit/Clang will accept.

 - parameter args: Compiler arguments, as parsed from `xcodebuild`.

 - returns: A tuple of partially filtered compiler arguments in `.0`, and whether or not there are
 more flags to remove in `.1`.
 */
private func partiallyFilter(arguments args: [String]) -> ([String], Bool) {
    guard let indexOfFlagToRemove = args.index(of: "-output-file-map") else {
        return (args, false)
    }
    var args = args
    args.remove(at: args.index(after: indexOfFlagToRemove))
    args.remove(at: indexOfFlagToRemove)
    return (args, true)
}

/**
 Filters compiler arguments from `xcodebuild` to something that SourceKit/Clang will accept.

 - parameter args: Compiler arguments, as parsed from `xcodebuild`.

 - returns: Filtered compiler arguments.
 */
private func filter(arguments args: [String]) -> [String] {
    var args = args
    args.append(contentsOf: ["-D", "DEBUG"])
    var shouldContinueToFilterArguments = true
    while shouldContinueToFilterArguments {
        (args, shouldContinueToFilterArguments) = partiallyFilter(arguments: args)
    }
    return args.filter {
        ![
            "-parseable-output",
            "-incremental",
            "-serialize-diagnostics",
            "-emit-dependencies"
        ].contains($0)
    }.map {
        if $0 == "-O" {
            return "-Onone"
        } else if $0 == "-DNDEBUG=1" {
            return "-DDEBUG=1"
        }
        return $0
    }
}
