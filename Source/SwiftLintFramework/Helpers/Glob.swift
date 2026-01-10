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
    static func resolveGlob(_ pattern: URL) -> [URL] {
        let globCharset = CharacterSet(charactersIn: "*?[]")
        guard pattern.path.rangeOfCharacter(from: globCharset) != nil else {
            return [pattern]
        }

        return expandGlobstar(pattern: pattern)
            .reduce(into: [URL]()) { paths, pattern in
#if os(Windows)
                paths.append(contentsOf: Self.windowsResolve(pattern))
#else
                var globResult = glob_t()
                defer { globfree(&globResult) }

                #if canImport(Musl)
                let flags = GLOB_TILDE | GLOB_MARK
                #else
                let flags = GLOB_TILDE | GLOB_BRACE | GLOB_MARK
                #endif
                if glob(pattern.path, flags, nil, &globResult) == 0 {
                    paths.append(contentsOf: populateFiles(globResult: globResult))
                }
#endif
            }
    }

    #if os(Windows)
    private static func windowsResolve(_ pattern: URL) -> [URL] {
        let wildcardSet = CharacterSet(charactersIn: "*?[]")

        let native = pattern.filepath
        guard native.rangeOfCharacter(from: wildcardSet) != nil else {
            return [pattern]
        }

        // Find base directory before the first wildcard in the native path
        var baseDirPath: String
        var remainder: String
        if let firstWCIndex = native.firstIndex(where: { "*?[]".contains($0) }) {
            let upToWildcard = native[..<firstWCIndex]
            if let lastSep = upToWildcard.lastIndex(where: { "/\\".contains($0) }) {
                baseDirPath = String(native[..<lastSep])
                remainder = String(native[native.index(after: lastSep)...])
            } else {
                baseDirPath = FileManager.default.currentDirectoryPath
                remainder = String(native)
            }
        } else {
            return [pattern]
        }

        let baseURL = baseDirPath.url(directoryHint: .isDirectory)
        let segments = remainder.split(whereSeparator: { "/\\".contains($0) }).map(String.init)
        return windowsExpand(base: baseURL, segments: ArraySlice(segments))
    }

    private static func windowsExpand(base: URL, segments: ArraySlice<String>) -> [URL] {
        guard let first = segments.first else {
            return [base]
        }

        let wildcardSet = CharacterSet(charactersIn: "*?[]")
        let isLast = segments.count == 1
        if first.rangeOfCharacter(from: wildcardSet) == nil {
            let nextBase = base.appending(path: first, directoryHint: .isDirectory)
            return windowsExpand(base: nextBase, segments: segments.dropFirst())
        }

        // Segment contains wildcard -> enumerate matches using FindFirstFileW
        var results = [URL]()
        let searchURL = base.appending(path: first)
        searchURL.withUnsafeFileSystemRepresentation { cPath in
            guard let cPath else { return }
            var ffd = WIN32_FIND_DATAW()
            let hFind: HANDLE = String(cString: cPath).withCString(encodedAs: UTF16.self) {
                FindFirstFileW($0, &ffd)
            }
            if hFind == INVALID_HANDLE_VALUE { return }
            defer { FindClose(hFind) }

            repeat {
                let name: String = withUnsafePointer(to: &ffd.cFileName) {
                    $0.withMemoryRebound(to: UInt16.self,
                                         capacity: MemoryLayout.size(ofValue: $0) / MemoryLayout<WCHAR>.size) {
                        String(decodingCString: $0, as: UTF16.self)
                    }
                }
                if name == "." || name == ".." { continue }
                let isDir = (ffd.dwFileAttributes & DWORD(FILE_ATTRIBUTE_DIRECTORY)) != 0
                let matchedURL = base.appending(path: name, directoryHint: isDir ? .isDirectory : .inferFromPath)

                if isLast {
                    results.append(matchedURL)
                } else if isDir {
                    let tail = segments.dropFirst()
                    results.append(contentsOf: windowsExpand(base: matchedURL, segments: tail))
                }
            } while FindNextFileW(hFind, &ffd)
        }

        return results
    }
    #endif

    static func createFilenameMatchers(root: String, pattern: String) -> [FilenameMatcher] {
        var absolutPathPattern = pattern
        #if os(Windows)
        if !pattern.contains(":") {
            // If the root is not already part of the pattern, prepend it.
            absolutPathPattern = root + (root.hasSuffix("/") ? "" : "/") + absolutPathPattern
        }
        #else
        if !pattern.starts(with: "/") {
            // If the root is not already part of the pattern, prepend it.
            absolutPathPattern = root + (root.hasSuffix("/") ? "" : "/") + absolutPathPattern
        }
        #endif
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

    private static func expandGlobstar(pattern: URL) -> [URL] {
        guard pattern.path.contains("**") else {
            return [pattern]
        }
        var parts = pattern.filepath.components(separatedBy: "**")
        let firstPart = parts.removeFirst()
        let fileManager = FileManager.default
        guard firstPart.isEmpty || fileManager.fileExists(atPath: firstPart) else {
            return []
        }
        let searchPath = firstPart.isEmpty ? fileManager.currentDirectoryPath : firstPart
        var directories = [URL]()
        do {
            directories = try fileManager.subpathsOfDirectory(atPath: searchPath).compactMap { subpath in
                let fullPath = firstPart.url().appending(path: subpath)
                guard fullPath.isDirectory else { return nil }
                return fullPath
            }
        } catch {
            Issue.genericWarning("Error parsing file system item: \(error)").print()
        }

        // Check the base directory for the glob star as well.
        directories.insert(firstPart.url(), at: 0)

        var lastPart = parts.joined(separator: "**")
        var results = [URL]()

        // Include the globstar root directory ("dir/") in a pattern like "dir/**" or "dir/**/"
        if lastPart.isEmpty {
            results.append(firstPart.url())
            lastPart = "*"
        }

        for directory in directories {
            results.append(contentsOf: expandGlobstar(pattern: directory.appending(path: lastPart)))
        }

        return results
    }

#if !os(Windows)
    private static func populateFiles(globResult: glob_t) -> [URL] {
#if os(Linux)
        let matchCount = globResult.gl_pathc
#else
        let matchCount = globResult.gl_matchc
#endif
        return (0..<Int(matchCount)).compactMap { index in
            globResult.gl_pathv[index].flatMap { String(validatingUTF8: $0)?.url() }
        }
    }
#endif
}
