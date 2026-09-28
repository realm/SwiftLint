import Foundation

struct CompilerArgumentsExtractor {
    static func allCompilerInvocations(compilerLogs: String) -> [[String]] {
        var compilerInvocations = [[String]]()
        compilerLogs.enumerateLines { line, _ in
            if let swiftcIndex = line.range(of: "swiftc ")?.upperBound, line.contains(" -module-name ") {
                let invocation = parseCLIArguments(String(line[swiftcIndex...]))
                    .expandingResponseFiles
                    .filteringCompilerArguments
                compilerInvocations.append(invocation)
            }
        }
        return compilerInvocations
    }
}

// MARK: - Private

private func parseCLIArguments(_ string: String) -> [String] {
    let escapedSpacePlaceholder = "\u{0}"
    let scanner = Scanner(string: string)
    var str = ""
    var didStart = false
    while !scanner.isAtEnd {
        var result: String? = scanner.scanUpToString("\"")
        if result == nil {
            result = ""
        }
        if didStart {
            str += result!.replacingOccurrences(of: " ", with: escapedSpacePlaceholder)
            str += " "
        } else {
            str += result!
        }
        if scanner.scanString("\"") != nil {
            didStart.toggle()
        } else {
            let remaining = String(scanner.string[scanner.currentIndex...])
            if didStart {
                str += remaining.replacingOccurrences(of: " ", with: escapedSpacePlaceholder)
            } else {
                str += remaining
            }
            break
        }
    }
    return str.trimmingCharacters(in: .whitespacesAndNewlines)
        .replacingOccurrences(of: "\\ ", with: escapedSpacePlaceholder)
        .components(separatedBy: .whitespacesAndNewlines)
        .filter { !$0.isEmpty }
        .map { $0.replacingOccurrences(of: escapedSpacePlaceholder, with: " ") }
}

/**
 Partially filters compiler arguments from `xcodebuild` to something that SourceKit/Clang will accept.

 - parameter args: Compiler arguments, as parsed from `xcodebuild`.

 - returns: A tuple of partially filtered compiler arguments in `.0`, and whether or not there are
 more flags to remove in `.1`.
 */
private func partiallyFilter(arguments args: [String]) -> ([String], Bool) {
    guard let indexOfFlagToRemove = args.firstIndex(of: "-output-file-map") else {
        return (args, false)
    }
    var args = args
    args.remove(at: args.index(after: indexOfFlagToRemove))
    args.remove(at: indexOfFlagToRemove)
    return (args, true)
}

extension Array where Element == String {
    /// Return the full list of compiler arguments, replacing any response files with their contents.
    fileprivate var expandingResponseFiles: [String] {
        flatMap { arg -> [String] in
            guard arg.starts(with: "@") else {
                return [arg]
            }
            let responseFile = String(arg.dropFirst())
            return (try? String(contentsOf: URL(filePath: responseFile, directoryHint: .notDirectory))).flatMap {
                // Response files may contain arguments separated by whitespace
                // (spaces, newlines) with quoting for paths containing spaces.
                // Reuse the CLI parser so both Xcode 25 (newline-separated) and
                // Xcode 26 (space-separated via @response files) layouts are
                // handled, including nested @ files.
                parseCLIArguments($0).expandingResponseFiles
            } ?? [arg]
        }
    }

    /// Returns filtered compiler arguments from `xcodebuild` to something that SourceKit/Clang will accept.
    var filteringCompilerArguments: [String] {
        var args = self
        if args.first == "swiftc" {
            args.removeFirst()
        }

        // https://github.com/realm/SwiftLint/issues/3365
        args = args.map { $0.replacingOccurrences(of: "\\=", with: "=") }
        args = args.map { $0.replacingOccurrences(of: "\\ ", with: " ") }
        args.append(contentsOf: ["-D", "DEBUG"])
        var shouldContinueToFilterArguments = true
        while shouldContinueToFilterArguments {
            (args, shouldContinueToFilterArguments) = partiallyFilter(arguments: args)
        }

        return args.filter { arg in
            ![
                "-parseable-output",
                "-incremental",
                "-serialize-diagnostics",
                "-emit-dependencies",
                "-use-frontend-parseable-output",
            ].contains(arg)
        }.map { arg in
            if arg == "-O" {
                return "-Onone"
            }
            if arg == "-DNDEBUG=1" {
                return "-DDEBUG=1"
            }
            return arg
        }
    }
}
