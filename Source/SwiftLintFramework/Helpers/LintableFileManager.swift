import Foundation

// MARK: - Protocol

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
}

// MARK: - FileManager Conformance

extension FileManager: LintableFileManager {
    public func filesToLint(inPath path: String, rootDirectory: String? = nil) -> [String] {
        let absolutePath = path.bridge()
            .absolutePathRepresentation(rootDirectory: rootDirectory ?? currentDirectoryPath).bridge()
            .standardizingPath

        // if path is a file, it won't be returned in `enumerator(atPath:)`
        if absolutePath.bridge().isSwiftFile() && absolutePath.isFile {
            return [absolutePath]
        }

        return subpaths(atPath: absolutePath)?.parallelCompactMap { element -> String? in
            guard element.bridge().isSwiftFile() else { return nil }
            let absoluteElementPath = absolutePath.bridge().appendingPathComponent(element)
            return absoluteElementPath.isFile ? absoluteElementPath : nil
        } ?? []
    }

    public func modificationDate(forFileAtPath path: String) -> Date? {
        return (try? attributesOfItem(atPath: path))?[.modificationDate] as? Date
    }
}

// MARK: - GitLintableFileManager

public class GitLintableFileManager {
    private let stableRevision: String
    public init(stableRevision: String) {
        self.stableRevision = stableRevision
    }
}

extension GitLintableFileManager: LintableFileManager {
    public func filesToLint(inPath path: String, rootDirectory: String? = nil) -> [String] {
        let changedFilesCommand = ["git", "diff", "--diff-filter=d", stableRevision, "--name-only", "--",
                                   path, "'*.swift'"]
        let changedFilesOutput = Exec.run("/usr/bin/env", changedFilesCommand)
        guard changedFilesOutput.terminationStatus == 0 else {
            queuedPrintError(
                "Could not get files changed from specified stable git revision. Falling back to file system traversal."
            )
            return FileManager.default.filesToLint(inPath: path, rootDirectory: rootDirectory)
        }

        let relativePaths = changedFilesOutput.string?.components(separatedBy: .newlines) ?? []
        return relativePaths.compactMap { relativePath in
            relativePath.bridge()
                .absolutePathRepresentation(
                    rootDirectory: rootDirectory ?? FileManager.default.currentDirectoryPath
                )
                .bridge()
                .standardizingPath
        }
    }

    public func modificationDate(forFileAtPath path: String) -> Date? {
        return FileManager.default.modificationDate(forFileAtPath: path)
    }
}
