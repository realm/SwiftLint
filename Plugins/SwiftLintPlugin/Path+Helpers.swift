import Foundation
import PackagePlugin

extension Path {
    /// Scans the receiver, then all of its parents looking for a configuration file with the name ".swiftlint.yml".
    ///
    /// - returns: Path to the configuration file, or nil if one cannot be found.
    func firstConfigurationFileInParentDirectories() -> Path? {
        let defaultConfigurationFileName = ".swiftlint.yml"
        let proposedDirectory = sequence(first: self, next: { $0.removingLastComponent() }).first { path in
            let potentialConfigurationFile = path.appending(subpath: defaultConfigurationFileName)
            return FileManager.default.isReadableFile(atPath: potentialConfigurationFile.string)
        }
        return proposedDirectory?.appending(subpath: defaultConfigurationFileName)
    }
}
