import Foundation

/// A namespace for the task-local current working directory.
///
/// In test code, set this per-task via `CurrentWorkingDirectory.$url.withValue(someURL) { ... }`
/// (or use the `.workingDirectory(_:)` / `.temporaryDirectory` test traits) instead of mutating
/// the process-wide `FileManager.default.currentDirectoryPath`. This allows tests that depend on
/// the working directory to run in parallel without interfering with each other.
public enum CurrentWorkingDirectory {
    /// The current working directory for the running task.
    ///
    /// `nil` means "use the process-wide CWD", i.e., `FileManager.default.currentDirectoryPath`).
    @TaskLocal public static var url: URL?
}

public extension URL {
    /// The current working directory.
    ///
    /// Returns the task-local override set via `CurrentWorkingDirectory.$url.withValue(_:)` when
    /// present, and falls back to the process-wide `FileManager.default.currentDirectoryPath`
    /// otherwise. Use this instead of reading `FileManager.default.currentDirectoryPath` directly.
    static var cwd: URL {
        if let url = CurrentWorkingDirectory.url {
            return url
        }
        return URL(filePath: FileManager.default.currentDirectoryPath, directoryHint: .isDirectory)
    }

    var filepath: String {
        withUnsafeFileSystemRepresentation { String(cString: $0!) }
    }

    var isSwiftFile: Bool {
        isFile && pathExtension == "swift"
    }

    var isFile: Bool {
        var isDirectoryObjC: ObjCBool = false
        if FileManager.default.fileExists(atPath: filepath, isDirectory: &isDirectoryObjC) {
            return !isDirectoryObjC.boolValue
        }
        return false
    }

    var isDirectory: Bool {
        var isDirectoryObjC: ObjCBool = false
        if FileManager.default.fileExists(atPath: filepath, isDirectory: &isDirectoryObjC) {
            return isDirectoryObjC.boolValue
        }
        return false
    }

    /// Path relative to the current working directory.
    ///
    /// > Warning: Use this representation only for displaying file paths to users. It is not
    ///   suitable for file operations.
    var relativeDisplayPath: String {
        let path = path.replacing(Self.cwd.path, with: "")
        if path.starts(with: "/") {
            return String(path.dropFirst())
        }
        return path
    }

    var exists: Bool {
        isFileURL && FileManager.default.fileExists(atPath: filepath)
    }

    func relative(to base: URL) -> URL {
        guard base.isFileURL, isFileURL else {
            return self
        }

        let baseComponents = base.standardizedFileURL.pathComponents
        let selfComponents = standardizedFileURL.pathComponents

        var index = 0
        while index < baseComponents.count, index < selfComponents.count,
              baseComponents[index] == selfComponents[index] {
            index += 1
        }

        var newPath = base
        for _ in index..<baseComponents.count {
            newPath.deleteLastPathComponent()
        }
        for component in selfComponents[index...] {
            newPath.append(path: component)
        }
        return newPath
    }
}

public extension String {
    func url(relativeTo base: URL? = nil, directoryHint: URL.DirectoryHint = .inferFromPath) -> URL {
        var resolvedBase = base ?? URL.cwd
        if resolvedBase.isDirectory {
            let lastComponent = resolvedBase.lastPathComponent
            resolvedBase.deleteLastPathComponent()
            resolvedBase.append(path: lastComponent, directoryHint: .isDirectory)
        }
        return URL(filePath: self, directoryHint: directoryHint, relativeTo: resolvedBase).standardizedFileURL
    }
}
