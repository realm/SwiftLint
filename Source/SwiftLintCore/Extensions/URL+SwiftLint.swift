import Foundation

public extension URL {
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
    var relativeFilepath: String {
        let path = filepath.replacing(URL.currentDirectory().filepath, with: "")
        if path.starts(with: "/") {
            return String(path.dropFirst())
        }
        return path
    }

    var exists: Bool {
        isFileURL && FileManager.default.fileExists(atPath: filepath)
    }

    func appending(components: [String]) -> URL {
        var url = self
        for component in components {
            url.append(path: component)
        }
        return url
    }

    func relative(to base: URL) -> URL {
        guard base.isFileURL, isFileURL else {
            return self
        }

        let baseComponents = base.standardized.pathComponents
        let selfComponents = standardized.pathComponents
        guard baseComponents != selfComponents.dropLast() else {
            // Same base.
            return self
        }

        var index = 0
        while index < baseComponents.count, index < selfComponents.count,
              baseComponents[index] == selfComponents[index] {
            index += 1
        }

        if index == baseComponents.count {
            // Base is parent directory.
            return self
        }

        var newSelf = self
        for _ in index..<baseComponents.count {
            newSelf.deleteLastPathComponent()
        }
        for component in selfComponents[index...] {
            newSelf.append(path: component)
        }
        return newSelf.standardized
    }

    func isChild(of base: URL) -> Bool {
        path.starts(with: base.path)
    }
}

public extension String {
    var url: URL {
        URL(filePath: self)
    }

    func url(relativeTo base: URL) -> URL {
        let baseDir = base.deletingLastPathComponent()
            .appending(path: base.lastPathComponent, directoryHint: .isDirectory)
        return URL(filePath: self, relativeTo: baseDir)
    }
}
