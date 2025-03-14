import Foundation

#if os(Linux)
#if canImport(Glibc)
import func Glibc.glob
#elseif canImport(Musl)
import func Musl.glob
#endif
#endif

// Adapted from https://gist.github.com/efirestone/ce01ae109e08772647eb061b3bb387c3

struct Glob {
    static func resolveGlob(_ pattern: String) -> [String] {
        #if os(Windows)
        // On Windows, use a simple path expansion
        let expandedPattern = NSString(string: pattern).expandingTildeInPath
        if FileManager.default.fileExists(atPath: expandedPattern) {
            return [expandedPattern]
        }
        return []
        #else
        return expandGlobstar(pattern: pattern)
            .reduce(into: [String]()) { paths, pattern in
                var globResult = glob_t()
                defer { globfree(&globResult) }

                #if os(Linux)
                let flags = GLOB_TILDE | GLOB_MARK
                #else
                let flags = GLOB_TILDE | GLOB_BRACE | GLOB_MARK
                #endif
                if glob(pattern, flags, nil, &globResult) == 0 {
                    paths.append(contentsOf: populateFiles(globResult: globResult))
                }
            }
        #endif
    }

    // MARK: Private

    private static func expandGlobstar(pattern: String) -> [String] {
        let expandedPattern = NSString(string: pattern).expandingTildeInPath
        if !expandedPattern.contains("**") {
            return [expandedPattern]
        }

        let parts = expandedPattern.components(separatedBy: "**")
        guard parts.count == 2 else {
            return [expandedPattern]
        }

        let fileManager = FileManager.default
        let prefix = parts[0]
        let suffix = parts[1]
        var directories: [String] = []

        func traverse(path: String) {
            guard let contents = try? fileManager.contentsOfDirectory(atPath: path) else {
                return
            }

            for item in contents {
                let itemPath = (path as NSString).appendingPathComponent(item)
                var isDirectory: ObjCBool = false
                if fileManager.fileExists(atPath: itemPath, isDirectory: &isDirectory) && isDirectory.boolValue {
                    directories.append(itemPath)
                    traverse(path: itemPath)
                }
            }
        }

        traverse(path: prefix)
        directories.append(prefix)

        return directories.map { ($0 as NSString).appendingPathComponent(suffix) }
    }

    #if !os(Windows)
    private static func populateFiles(globResult: glob_t) -> [String] {
        #if os(Linux)
        let matchCount = globResult.gl_pathc
        #else
        let matchCount = globResult.gl_matchc
        #endif

        return (0..<Int(matchCount)).compactMap { index in
            guard let path = globResult.gl_pathv[index] else { return nil }
            return String(cString: path)
        }
    }
    #endif
}
