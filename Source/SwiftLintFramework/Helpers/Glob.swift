#if os(Linux)
import Glibc

let globFunction = Glibc.glob
#else
import Darwin

let globFunction = Darwin.glob
#endif

struct Glob {
    static func resolveGlob(_ pattern: String) -> [String] {
        guard pattern.contains("*") else {
            return [pattern]
        }

        var globResult = glob_t()
        defer { globfree(&globResult) }

        let flags = GLOB_TILDE | GLOB_BRACE | GLOB_MARK
        guard globFunction(pattern.cString(using: .utf8)!, flags, nil, &globResult) == 0 else {
            return []
        }

#if os(Linux)
        let matchCount = globResult.gl_pathc
#else
        let matchCount = globResult.gl_matchc
#endif

        return (0..<Int(matchCount)).compactMap { index in
            return globResult.gl_pathv[index].flatMap { String(validatingUTF8: $0) }
        }
    }
}
