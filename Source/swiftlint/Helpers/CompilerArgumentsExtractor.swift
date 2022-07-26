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
    while let result = scanner.scanUpToString("\"") {
        if didStart {
            str += result.replacingOccurrences(of: " ", with: escapedSpacePlaceholder)
            str += " "
        } else {
            str += result
        }
        _ = scanner.scanString("\"")
        didStart.toggle()
    }
    return str.trimmingCharacters(in: .whitespaces)
        .replacingOccurrences(of: "\\ ", with: escapedSpacePlaceholder)
        .components(separatedBy: " ")
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
        return flatMap { arg -> [String] in
            guard arg.starts(with: "@") else {
                return [arg]
            }
            let responseFile = String(arg.dropFirst())
            return (try? String(contentsOf: URL(fileURLWithPath: responseFile, isDirectory: false))).flatMap {
                $0.trimmingCharacters(in: .newlines)
                  .components(separatedBy: "\n")
                  .expandingResponseFiles
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
}
