import Foundation

public extension URL {
    static var cwd: URL {
        FileManager.default.currentDirectoryPath.url(directoryHint: .isDirectory)
    }

    var filepath: String {
        withUnsafeFileSystemRepresentation { String(cString: $0!) }
    }

    var filepathGuarded: String? {
        withUnsafeFileSystemRepresentation { ptr in
            guard let ptr else {
                Issue.genericError(
                    "File with URL '\(self)' cannot be represented as a file system path; skipping it"
                ).print()
                return nil
            }
            return String(cString: ptr)
        }
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
        let path = path.replacing(URL.cwd.path, with: "")
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
        guard var base else {
            return URL(filePath: self, directoryHint: directoryHint).standardizedFileURL
        }
        if base.isDirectory {
            let lastComponent = base.lastPathComponent
            base.deleteLastPathComponent()
            base.append(path: lastComponent, directoryHint: .isDirectory)
        }
        return URL(filePath: self, directoryHint: directoryHint, relativeTo: base).standardizedFileURL
    }
}
