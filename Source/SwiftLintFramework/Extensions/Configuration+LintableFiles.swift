import Foundation
import SourceKittenFramework

#if os(Linux)
import Glibc

let globFunction = Glibc.glob
#else
import Darwin

let globFunction = Darwin.glob
#endif

extension Configuration {
    public func lintableFiles(inPath path: String, forceExclude: Bool) -> [File] {
        return lintablePaths(inPath: path, forceExclude: forceExclude).compactMap(File.init(pathDeferringReading:))
    }

    internal func lintablePaths(inPath path: String, forceExclude: Bool,
                                fileManager: LintableFileManager = FileManager.default) -> [String] {
        // If path is a file and we're not forcing excludes, skip filtering with excluded/included paths
        if path.isFile && !forceExclude {
            return [path]
        }
        let pathsForPath = included.isEmpty ? fileManager.filesToLint(inPath: path, rootDirectory: nil) : []
        let excludedPaths = excluded
            .flatMap { resolveGlobs(in: $0) }
            .flatMap {
                fileManager.filesToLint(inPath: $0, rootDirectory: rootPath)
            }
        let includedPaths = included.flatMap {
            fileManager.filesToLint(inPath: $0, rootDirectory: rootPath)
        }
        return (pathsForPath + includedPaths).filter {
            !excludedPaths.contains($0)
        }
    }

    private func resolveGlobs(in pattern: String) -> [String] {
        guard pattern.contains("*") else {
            return [pattern]
        }

        var globResult = glob_t()
        defer { globfree(&globResult) }

        let flags = GLOB_TILDE | GLOB_BRACE | GLOB_MARK
        guard globFunction(pattern.cString(using: .utf8)!, flags, nil, &globResult) == 0 else {
            return []
        }

#if os(Linux)
        let matchCount = globResult.gl_pathc
#else
        let matchCount = globResult.gl_matchc
#endif

        return (0..<Int(matchCount)).compactMap { index in
            return String(validatingUTF8: globResult.gl_pathv[index]!)
        }
    }
}
