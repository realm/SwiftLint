import Foundation
import PackagePlugin

extension Path {
    var directoryContainsConfigFile: Bool {
        FileManager.default.fileExists(atPath: "\(self)/.swiftlint.yml")
    }

    var depth: Int {
        URL(fileURLWithPath: "\(self)").pathComponents.count
    }

    func isDescendant(of path: Path) -> Bool {
        "\(self)".hasPrefix("\(path)")
    }

    func resolveWorkingDirectory(in directory: Path) throws -> Path {
        guard "\(self)".hasPrefix("\(directory)") else {
            throw SwiftLintBuildToolPluginError.pathNotInDirectory(path: self, directory: directory)
        }

        let path: Path? = sequence(first: self) { path in
            let path: Path = path.removingLastComponent()
            guard "\(path)".hasPrefix("\(directory)") else {
                return nil
            }
            return path
        }
        .reversed()
        .first(where: \.directoryContainsConfigFile)

        return path ?? directory
    }
}
