import Foundation
import PackagePlugin

extension URL {
    var filepath: String {
        withUnsafeFileSystemRepresentation { String(cString: $0!) }
    }

    var depth: Int {
        pathComponents.count
    }

    func isDescendant(of other: URL) -> Bool {
        path().hasPrefix(other.path())
    }

    func resolvedWorkingDirectory(in directory: URL) throws -> URL {
        guard isDescendant(of: directory) else {
            throw SwiftLintBuildToolPluginError.pathNotInDirectory(path: self, directory: directory)
        }

        let path: URL? = sequence(first: self) { path in
                let path = path.deletingLastPathComponent()
                guard path.isDescendant(of: directory) else {
                    return nil
                }
                return path
        }
            .reversed()
            .first {
                let file = $0.appending(path: ".swiftlint.yml", directoryHint: .notDirectory).filepath
                return FileManager.default.fileExists(atPath: file)
            }

        return path ?? directory
    }
}
