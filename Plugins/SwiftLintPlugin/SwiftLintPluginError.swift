import PackagePlugin

enum SwiftLintPluginError: Error, CustomStringConvertible {
    case pathNotInDirectory(path: Path, directory: Path)
    case swiftFilesNotInProjectDirectory(Path)
    case swiftFilesNotInWorkingDirectory(Path)

    var description: String {
        switch self {
        case let .pathNotInDirectory(path, directory):
            return """
                Path is not in directory.
                Path: \(path)
                Directory: \(directory)
                """
        case let .swiftFilesNotInProjectDirectory(directory):
            return """
                Swift files are not in project directory.
                Directory: \(directory)
                """
        case let .swiftFilesNotInWorkingDirectory(directory):
            return """
                Swift files are not in working directory.
                Directory: \(directory)
                """
        }
    }
}
