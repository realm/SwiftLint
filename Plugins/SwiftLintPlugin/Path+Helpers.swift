import Foundation
import PackagePlugin

#if os(Linux)
import Glibc
#else
import Darwin
#endif

extension Path {
    /// Scans the receiver, then all of its parents looking for a configuration file with the name ".swiftlint.yml".
    ///
    /// - returns: Path to the configuration file, or nil if one cannot be found.
    func firstConfigurationFileInParentDirectories() -> Path? {
        let defaultConfigurationFileName = ".swiftlint.yml"
        let proposedDirectory = parents.first { path in
            let potentialConfigurationFile = path.appending(subpath: defaultConfigurationFileName)
            return potentialConfigurationFile.isAccessible()
        }
        return proposedDirectory?.appending(subpath: defaultConfigurationFileName)
    }

    /// Safe way to check if the file is accessible from within the current process sandbox.
    private func isAccessible() -> Bool {
        let result = string.withCString { pointer in
            access(pointer, R_OK)
        }

        return result == 0
    }

    private var parents: any Sequence<Path> {
        sequence(
            first: self,
            next: { path in
                guard path.stem.count > 1 else {
                    // Check we're not at the root of this filesystem, as `removingLastComponent()`
                    // will continually return the root from itself.
                    return nil
                }

                return path.removingLastComponent()
            }
        )
    }

    public func relative(to base: Path) -> Path {
        let result: String
        // Split the two paths into their components.
        // FIXME: The is needs to be optimized to avoid unncessary copying.
        let pathComps = self.parents.reversed()
        let baseComps = base.parents.reversed()

        // It's common for the base to be an ancestor, so try that first.
        if pathComps.starts(with: baseComps) {
            // Special case, which is a plain path without `..` components.  It
            // might be an empty path (when self and the base are equal).
            let relComps = pathComps.dropFirst(baseComps.count).map(\.lastComponent)
#if os(Windows)
            result = Array(relComps).joined(separator: "\\")
#else
            result = Array(relComps).joined(separator: "/")
#endif
        } else {
            // General case, in which we might well need `..` components to go
            // "up" before we can go "down" the directory tree.
            var newPathComps = ArraySlice(pathComps)
            var newBaseComps = ArraySlice(baseComps)
            while newPathComps.prefix(1) == newBaseComps.prefix(1) {
                // First component matches, so drop it.
                newPathComps = newPathComps.dropFirst()
                newBaseComps = newBaseComps.dropFirst()
            }
            // Now construct a path consisting of as many `..`s as are in the
            // `newBaseComps` followed by what remains in `newPathComps`.
            var relComps = Array(repeating: "..", count: newBaseComps.count)
            relComps.append(contentsOf: newPathComps.map(\.lastComponent))
#if os(Windows)
            result = relComps.joined(separator: "\\")
#else
            result = relComps.joined(separator: "/")
#endif
        }

        return Path(result)
    }
}
