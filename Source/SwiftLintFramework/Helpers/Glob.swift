import Foundation

#if canImport(Darwin)
import Darwin

private let globFunction = Darwin.glob
#elseif canImport(Glibc)
import Glibc

private let globFunction = Glibc.glob
#else
#error("Unsupported platform")
#endif

struct Glob {
    static func resolveGlob(_ pattern: String) -> [String] {
        let globCharset = CharacterSet(charactersIn: "*?[]")
        guard pattern.rangeOfCharacter(from: globCharset) != nil else {
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
