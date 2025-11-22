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

    /// Returns true if a file (but not a directory) exists at the specified path.
    ///
    /// - parameter path: The path that should be checked to see if it is a file.
    ///
    /// - returns: true if the specified path is a file.
    func isFile(atPath path: String) -> Bool
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

extension FileManager: LintableFileManager {
    public func filesToLint(inPath path: String,
                            rootDirectory: String? = nil,
                            excluder: Excluder) -> [String] {
        let absolutePath = path.bridge()
            .absolutePathRepresentation(rootDirectory: rootDirectory ?? currentDirectoryPath).bridge()
            .standardizingPath

        // If path is a file, it won't be returned in `enumerator(atPath:)`.
        if absolutePath.bridge().isSwiftFile(), absolutePath.isFile {
            return excluder.excludes(path: absolutePath) ? [] : [absolutePath]
        }

        guard let enumerator = enumerator(atPath: absolutePath) else {
            return []
        }

        var files = [String]()
        while let element = enumerator.nextObject() as? String {
            let absoluteElementPath = absolutePath.bridge().appendingPathComponent(element)
            if absoluteElementPath.bridge().isSwiftFile(), absoluteElementPath.isFile {
                if !excluder.excludes(path: absoluteElementPath) {
                    files.append(absoluteElementPath)
                }
            } else if excluder.excludes(path: absoluteElementPath) {
                enumerator.skipDescendants()
            }
        }
        return files
    }

    public func modificationDate(forFileAtPath path: String) -> Date? {
        (try? attributesOfItem(atPath: path))?[.modificationDate] as? Date
    }

    public func isFile(atPath path: String) -> Bool {
        path.isFile
    }
}
