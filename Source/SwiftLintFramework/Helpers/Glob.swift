import FilenameMatcher
import Foundation
import SourceKittenFramework

#if os(Linux)
#if canImport(Glibc)
import func Glibc.glob
#elseif canImport(Musl)
import func Musl.glob
#endif
#endif

#if os(Windows)
import WinSDK
#endif

// Adapted from https://gist.github.com/efirestone/ce01ae109e08772647eb061b3bb387c3

struct Glob {
    static func resolveGlob(_ pattern: String) -> [String] {
        let globCharset = CharacterSet(charactersIn: "*?[]")
        guard pattern.rangeOfCharacter(from: globCharset) != nil else {
            return [pattern]
        }

        return expandGlobstar(pattern: pattern)
            .reduce(into: [String]()) { paths, pattern in
#if os(Windows)
                URL(fileURLWithPath: pattern).withUnsafeFileSystemRepresentation {
                    var ffd = WIN32_FIND_DATAW()

                    let hDirectory: HANDLE = String(cString: $0!).withCString(encodedAs: UTF16.self) {
                        FindFirstFileW($0, &ffd)
                    }
                    if hDirectory == INVALID_HANDLE_VALUE { return }
                    defer { FindClose(hDirectory) }

                    repeat {
                        let path: String = withUnsafePointer(to: &ffd.cFileName) {
                            $0.withMemoryRebound(to: UInt16.self,
                                                 capacity: MemoryLayout.size(ofValue: $0) / MemoryLayout<WCHAR>.size) {
                                String(decodingCString: $0, as: UTF16.self)
                            }
                        }
                        if path == "." || path == ".." { continue }
                        paths.append(path)
                    } while FindNextFileW(hDirectory, &ffd)
                }
#else
                var globResult = glob_t()
                defer { globfree(&globResult) }

                #if canImport(Musl)
                let flags = GLOB_TILDE | GLOB_MARK
                #else
                let flags = GLOB_TILDE | GLOB_BRACE | GLOB_MARK
                #endif
                if glob(pattern, flags, nil, &globResult) == 0 {
                    paths.append(contentsOf: populateFiles(globResult: globResult))
                }
#endif
            }
            .unique
            .sorted()
            .map { $0.absolutePathStandardized() }
    }

    static func createFilenameMatchers(root: String, pattern: String) -> [FilenameMatcher] {
        var absolutPathPattern = pattern
        if !pattern.starts(with: root) {
            // If the root is not already part of the pattern, prepend it.
            absolutPathPattern = root + (root.hasSuffix("/") ? "" : "/") + absolutPathPattern
        }
        absolutPathPattern = absolutPathPattern.absolutePathStandardized()
        if pattern.hasSuffix(".swift") || pattern.hasSuffix("/**") {
            // Suffix is already well defined.
            return [FilenameMatcher(pattern: absolutPathPattern)]
        }
        if pattern.hasSuffix("/") {
            // Matching all files in the folder.
            return [FilenameMatcher(pattern: absolutPathPattern + "**")]
        }
        // The pattern could match files in the last folder in the path or all contained files if the last component
        // represents folders.
        return [
            FilenameMatcher(pattern: absolutPathPattern),
            FilenameMatcher(pattern: absolutPathPattern + "/**"),
        ]
    }

    // MARK: Private

    private static func expandGlobstar(pattern: String) -> [String] {
        guard pattern.contains("**") else {
            return [pattern]
        }
        var parts = pattern.components(separatedBy: "**")
        let firstPart = parts.removeFirst()
        let fileManager = FileManager.default
        guard firstPart.isEmpty || fileManager.fileExists(atPath: firstPart) else {
            return []
        }
        let searchPath = firstPart.isEmpty ? fileManager.currentDirectoryPath : firstPart
        // Enumerate lazily with a per-item error handler. `subpathsOfDirectory(atPath:)`, used
        // previously, is all-or-nothing: a single unreadable entry (permission denied, dangling
        // symlink, a file removed mid-scan, …) makes it throw, discarding every directory found
        // so far. On large trees (50k+ files) hitting such an entry is likely, which left only
        // the root directory to be globbed and silently ignored all nested files.
        let enumerator = fileManager.enumerator(
            at: URL(fileURLWithPath: searchPath, isDirectory: true),
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [],
            errorHandler: { _, error in
                Issue.genericWarning("Error parsing file system item: \(error)").print()
                return true
            }
        )
        var directories: [String] = enumerator?.compactMap { item in
            guard let url = item as? URL,
                  (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true else {
                return nil
            }
            return url.path
        } ?? []

        // Check the base directory for the glob star as well.
        directories.insert(firstPart, at: 0)

        var lastPart = parts.joined(separator: "**")
        var results = [String]()

        // Include the globstar root directory ("dir/") in a pattern like "dir/**" or "dir/**/"
        if lastPart.isEmpty {
            results.append(firstPart)
            lastPart = "*"
        }

        for directory in directories {
            let partiallyResolvedPattern: String
            if directory.isEmpty {
                partiallyResolvedPattern = lastPart.starts(with: "/") ? String(lastPart.dropFirst()) : lastPart
            } else {
                partiallyResolvedPattern = directory.bridge().appendingPathComponent(lastPart)
            }
            results.append(contentsOf: expandGlobstar(pattern: partiallyResolvedPattern))
        }

        return results
    }

#if !os(Windows)
    private static func populateFiles(globResult: glob_t) -> [String] {
#if os(Linux)
        let matchCount = globResult.gl_pathc
#else
        let matchCount = globResult.gl_matchc
#endif
        return (0..<Int(matchCount)).compactMap { index in
            globResult.gl_pathv[index].flatMap { String(validatingUTF8: $0) }
        }
    }
#endif
}
