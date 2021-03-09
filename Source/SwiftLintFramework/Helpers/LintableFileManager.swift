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

/// A producer of lintable files that compares against a stable git revision.
public class GitLintableFileManager {
    private let stableRevision: String
    private let explicitConfigurationPaths: [String]

    /// Creates a `GitLintableFileManager` with the specified stable revision.
    ///
    /// - parameter stableRevision:             The stable git revision to compare lintable files against.
    /// - parameter explicitConfigurationPaths: The explicit configuration file paths specified by the user.
    public init(stableRevision: String, explicitConfigurationPaths: [String]) {
        self.stableRevision = stableRevision
        self.explicitConfigurationPaths = explicitConfigurationPaths
    }
}

extension GitLintableFileManager: LintableFileManager {
    /// Returns all files that can be linted in the specified path. If the path is relative, it will be appended to the
    /// specified root path, or current working directory if no root directory is specified.
    ///
    /// - parameter path:          The path in which lintable files should be found.
    /// - parameter rootDirectory: The parent directory for the specified path. If none is provided, the current working
    ///                            directory will be used.
    ///
    /// - returns: Files to lint.
    public func filesToLint(inPath path: String, rootDirectory: String? = nil) -> [String] {
        func git(_ args: [String]) -> [String]? {
            let out = Exec.run("/usr/bin/env", ["git"] + args)
            if out.terminationStatus == 0 {
                return out.string?.components(separatedBy: .newlines) ?? []
            } else {
                return nil
            }
        }

        func fallback(reason: GitFallbackReason) -> [String] {
            queuedPrintError(
                "\(reason.description) from specified stable git revision. Falling back to file system traversal."
            )
            return FileManager.default.filesToLint(inPath: path, rootDirectory: rootDirectory)
        }

        guard let mergeBase = git(["merge-base", stableRevision, "HEAD"])?.first else {
            return fallback(reason: .mergeBaseNotFound)
        }

        func allFilesChanged(filters: [String]) -> [String]? {
            guard let changed = git(["diff", "--name-only", "--diff-filter=AMRCU", mergeBase, "--", path] + filters),
                  let untracked = git(["ls-files", "--others", "--exclude-standard", "--", path] + filters)
            else {
                return nil
            }

            return changed + untracked
        }

        if let configurationFiles = allFilesChanged(filters: ["'*.swiftlint.yml'"] + explicitConfigurationPaths),
           !configurationFiles.isEmpty {
            return fallback(reason: .configChanged)
        }

        guard let filesToLint = allFilesChanged(filters: ["'*.swift'"]) else {
            return fallback(reason: .filesChangedNotFound)
        }

        return filesToLint.compactMap { relativePath in
            relativePath.bridge()
                .absolutePathRepresentation(
                    rootDirectory: rootDirectory ?? FileManager.default.currentDirectoryPath
                )
                .bridge()
                .standardizingPath
        }
    }

    /// Returns the date when the file at the specified path was last modified. Returns `nil` if the file cannot be
    /// found or its last modification date cannot be determined.
    ///
    /// - parameter path: The file whose modification date should be determined.
    ///
    /// - returns: A date, if one was determined.
    public func modificationDate(forFileAtPath path: String) -> Date? {
        return FileManager.default.modificationDate(forFileAtPath: path)
    }
}

private enum GitFallbackReason {
    case mergeBaseNotFound, configChanged, filesChangedNotFound

    var description: String {
        switch self {
        case .mergeBaseNotFound:
            return "Merge base not found"
        case .configChanged:
            return "Configuration files changed"
        case .filesChangedNotFound:
            return "Could not get changed files"
        }
    }
}
