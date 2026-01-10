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

    func excludes(path: URL) -> Bool {
        let standardized = path.standardized.path
        return switch self {
        case let .matching(matchers):
            matchers.contains(where: { $0.match(filename: standardized) })
        case let .byPrefix(prefixes):
            prefixes.contains(where: { standardized.hasPrefix($0) })
        case .noExclusion:
            false
        }
    }
}

#if os(macOS)
extension FileManager: @unchecked @retroactive Sendable {}
#endif

extension FileManager: LintableFileManager {
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
        guard let enumerator = enumerator(atPath: absolutePath.filepath) else {
            return []
        }

        var files = [URL]()
        var directoriesToWalk = [URL]()

        while let element = enumerator.nextObject() as? String {
            let absoluteElementPath = element.url(relativeTo: absolutePath)
            if absoluteElementPath.isFile {
                if absoluteElementPath.pathExtension == "swift",
                   !excluder.excludes(path: absoluteElementPath) {
                    files.append(absoluteElementPath)
                }
            } else {
                enumerator.skipDescendants()
                if !excluder.excludes(path: absoluteElementPath) {
                    directoriesToWalk.append(absoluteElementPath)
                }
            }
        }

        return files + directoriesToWalk.parallelFlatMap {
            collectFiles(atPath: $0, excluder: excluder)
        }
    }

    public func modificationDate(forFileAtPath path: URL) -> Date? {
        (try? attributesOfItem(atPath: path.filepath))?[.modificationDate] as? Date
    }
}
