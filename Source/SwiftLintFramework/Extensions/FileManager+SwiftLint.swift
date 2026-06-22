import FilenameMatcher
import Foundation
import SourceKittenFramework

/// An interface for enumerating files that can be linted by SwiftLint.
public protocol LintableFileManager {
    /// Returns all files that can be linted in the specified path. If the path is relative, it will be appended to the
    /// specified root path, or current working directory if no root directory is specified.
    ///
    /// - parameter path:          The path in which lintable files should be found.
    /// - parameter rootDirectory: The parent directory for the specified path. If none is provided, the current working
    ///                            directory will be used.
    /// - parameter excluder:     The excluder used to filter out files that should not be linted.
    ///
    /// - returns: Files to lint.
    func filesToLint(inPath path: URL, excluder: Excluder) -> [URL]

    /// Returns the date when the file at the specified path was last modified. Returns `nil` if the file cannot be
    /// found or its last modification date cannot be determined.
    ///
    /// - parameter path: The file whose modification date should be determined.
    ///
    /// - returns: A date, if one was determined.
    func modificationDate(forFileAtPath path: URL) -> Date?
}

/// An excluder for filtering out files that should not be linted.
public enum Excluder {
    /// Full matching excluder using filename matchers.
    case matching(matchers: [FilenameMatcher])
    /// Prefix-based excluder using path prefixes.
    case byPrefix(prefixes: [String])
    /// An excluder that does not exclude any files.
    case noExclusion

    private static let privatePrefix = "/private"

    func excludes(path: URL) -> Bool {
        if case .noExclusion = self {
            return false
        }

        // Exclusion matchers and prefixes are derived from standardized URLs (see `String.url()`),
        // which on macOS drops a leading `/private` from paths under firmlinks such as `/tmp` and
        // `/var`. Paths produced by `FileManager`'s directory enumerator keep that prefix, so a
        // file under a `/private`-resolved directory (e.g. CI workspaces or `mktemp` directories)
        // would never match. Compare against the path with and without the `/private` prefix to
        // bridge the gap without touching the filesystem; standardizing every candidate via
        // `standardizedFileURL` would `stat` each path and is measurably slower.
        let fullPath = path.path
        let strippedPath = fullPath.hasPrefix(Self.privatePrefix + "/")
            ? String(fullPath.dropFirst(Self.privatePrefix.count))
            : nil
        return switch self {
            case let .matching(matchers):
                matchers.contains { matcher in
                    matcher.match(filename: fullPath) || strippedPath.map { matcher.match(filename: $0) } == true
                }
            case let .byPrefix(prefixes):
                prefixes.contains { prefix in
                    fullPath.hasPrefix(prefix) || strippedPath?.hasPrefix(prefix) == true
                }
            case .noExclusion:
                queuedFatalError("Unreachable case; should have been handled at the beginning of the method")
            }
    }
}

#if os(macOS)
extension FileManager: @unchecked @retroactive Sendable {}
#endif

extension FileManager: LintableFileManager {
    private static let enumeratorProperties: Set<URLResourceKey> = [
        .isRegularFileKey,
        .isSymbolicLinkKey,
    ]
    private static let enumeratorOptions: DirectoryEnumerationOptions = [
        .skipsPackageDescendants,
        .skipsSubdirectoryDescendants,
    ]

    public func filesToLint(inPath path: URL, excluder: Excluder) -> [URL] {
        // If path is a file, filter and return it directly.
        if path.isSwiftFile {
            return excluder.excludes(path: path) ? [] : [path]
        }

        // Fast path when there are no exclusions.
        if case .noExclusion = excluder {
            return subpaths(atPath: path.filepath)?.parallelCompactMap { element in
                let absoluteElementPath = element.url(relativeTo: path)
                return absoluteElementPath.isSwiftFile ? absoluteElementPath : nil
            } ?? []
        }

        return collectFiles(atPath: path, excluder: excluder)
    }

    private func collectFiles(atPath absolutePath: URL, excluder: Excluder) -> [URL] {
        let enumerator = enumerator(
            at: absolutePath,
            includingPropertiesForKeys: Array(Self.enumeratorProperties),
            options: Self.enumeratorOptions
        )
        guard let enumerator else {
            return []
        }

        var files = [URL]()
        var directoriesToWalk = [URL]()

        for case var element as URL in enumerator {
            var resourceValues = try? element.resourceValues(forKeys: Self.enumeratorProperties)
            if resourceValues?.isSymbolicLink == true {
                element = element.standardizedFileURL
                if excluder.excludes(path: element) {
                    continue
                }
                element.resolveSymlinksInPath()
                resourceValues = try? element.resourceValues(forKeys: Self.enumeratorProperties)
            }
            if resourceValues?.isRegularFile == true {
                if element.pathExtension == "swift", !excluder.excludes(path: element) {
                    files.append(element)
                }
            } else if resourceValues != nil, !excluder.excludes(path: element) {
                directoriesToWalk.append(element)
            }
        }

        return files + directoriesToWalk.parallelFlatMap { collectFiles(atPath: $0, excluder: excluder) }
    }

    public func modificationDate(forFileAtPath path: URL) -> Date? {
        (try? attributesOfItem(atPath: path.filepath))?[.modificationDate] as? Date
    }
}
