import PackagePlugin

enum SwiftLintBuildToolPluginError: Error, CustomStringConvertible {
    case pathNotInDirectory(path: Path, directory: Path)
    case swiftFilesNotInProjectDirectory(Path)
    case swiftFilesNotInWorkingDirectory(Path)

    var description: String {
        switch self {
        case let .pathNotInDirectory(path, directory):
            "Path '\(path)' is not in directory '\(directory)'."
        case let .swiftFilesNotInProjectDirectory(directory):
            "Swift files are not in project directory '\(directory)'."
        case let .swiftFilesNotInWorkingDirectory(directory):
            "Swift files are not in working directory '\(directory)'."
        }
    }
}
