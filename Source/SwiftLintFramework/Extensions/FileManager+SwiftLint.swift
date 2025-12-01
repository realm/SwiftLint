import Foundation
import SourceKittenFramework

/// An interface for enumerating files that can be linted by SwiftLint.
public protocol LintableFileManager {
    /// Returns all files that can be linted in the specified path. If the path is relative, it will be appended to the
    /// specified root path, or currentt working directory if no root directory is specified.
    ///
    /// - parameter path:          The path in which lintable files should be found.
    /// - parameter rootDirectory: The parent directory for the specified path. If none is provided, the current working
    ///                            directory will be used.
    ///
    /// - returns: Files to lint.
    func filesToLint(inPath path: String, rootDirectory: String?) -> [String]

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

extension FileManager: LintableFileManager {
    public func filesToLint(inPath path: String, rootDirectory: String? = nil) -> [String] {
        let root =
            URL(fileURLWithPath: path.absolutePathRepresentation(rootDirectory: rootDirectory ?? currentDirectoryPath))

        // if path is a file, it won't be returned in `enumerator(atPath:)`
        if root.isSwiftFile { return [root.standardized.filepath] }

        return subpaths(atPath: root.path)?.parallelCompactMap { element -> String? in
            let elementURL = URL(fileURLWithPath: element, relativeTo: root)
            if elementURL.isSwiftFile {
                return elementURL.standardized.filepath
            }
            return nil
        } ?? []
    }

    public func modificationDate(forFileAtPath path: String) -> Date? {
        (try? attributesOfItem(atPath: path))?[.modificationDate] as? Date
    }

    public func isFile(atPath path: String) -> Bool {
        path.isFile
    }
}
