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
    func filesToLint(inPath path: String, rootDirectory: String?, excluder: Excluder) -> [String]

    /// Returns the date when the file at the specified path was last modified. Returns `nil` if the file cannot be
    /// found or its last modification date cannot be determined.
    ///
    /// - parameter path: The file whose modification date should be determined.
    ///
    /// - returns: A date, if one was determined.
    func modificationDate(forFileAtPath path: String) -> Date?
}

/// An excluder for filtering out files that should not be linted.
public enum Excluder {
    /// Full matching excluder using filename matchers.
    case matching(matchers: [FilenameMatcher])
    /// Prefix-based excluder using path prefixes.
    case byPrefix(prefixes: [String])
    /// An excluder that does not exclude any files.
    case noExclusion

    func excludes(path: String) -> Bool {
        switch self {
        case let .matching(matchers):
            matchers.contains(where: { $0.match(filename: path) })
        case let .byPrefix(prefixes):
            prefixes.contains(where: { path.hasPrefix($0) })
        case .noExclusion:
            false
        }
    }
}

extension FileManager: LintableFileManager, @unchecked @retroactive Sendable {
    public func filesToLint(inPath path: String,
                            rootDirectory: String? = nil,
                            excluder: Excluder) -> [String] {
        let absolutePath = URL(
            fileURLWithPath: path.absolutePathRepresentation(rootDirectory: rootDirectory ?? currentDirectoryPath)
        )

        // If path is a file, filter and return it directly.
        if absolutePath.isSwiftFile {
            let filePath = absolutePath.standardized.filepath
            return excluder.excludes(path: filePath) ? [] : [filePath]
        }

        // Fast path when there are no exclusions.
        if case .noExclusion = excluder {
            return subpaths(atPath: absolutePath.filepath)?.parallelCompactMap { element in
                let absoluteElementPath = URL(fileURLWithPath: element, relativeTo: absolutePath)
                return absoluteElementPath.isSwiftFile ? absoluteElementPath.standardized.filepath : nil
            } ?? []
        }

        return collectFiles(atPath: absolutePath, excluder: excluder)
    }

    private func collectFiles(atPath absolutePath: URL, excluder: Excluder) -> [String] {
        guard let enumerator = enumerator(atPath: absolutePath.filepath) else {
            return []
        }

        var files = [String]()
        var directoriesToWalk = [String]()

        while let element = enumerator.nextObject() as? String {
            let absoluteElementPath = URL(fileURLWithPath: element, relativeTo: absolutePath)
            let absoluteStandardizedElementPath = absoluteElementPath.standardized.filepath
            if absoluteElementPath.path.isFile {
                if absoluteElementPath.pathExtension == "swift",
                   !excluder.excludes(path: absoluteStandardizedElementPath) {
                    files.append(absoluteStandardizedElementPath)
                }
            } else {
                enumerator.skipDescendants()
                if !excluder.excludes(path: absoluteStandardizedElementPath) {
                    directoriesToWalk.append(absoluteStandardizedElementPath)
                }
            }
        }

        return files + directoriesToWalk.parallelFlatMap {
            collectFiles(atPath: URL(fileURLWithPath: $0), excluder: excluder)
        }
    }

    public func modificationDate(forFileAtPath path: String) -> Date? {
        (try? attributesOfItem(atPath: path))?[.modificationDate] as? Date
    }
}
