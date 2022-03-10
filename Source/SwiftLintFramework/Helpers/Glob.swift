import Foundation
import Pathos

struct Glob {
    static func resolveGlob(_ pattern: String) -> [String] {
        let globCharset = CharacterSet(charactersIn: "*?[]")
        guard pattern.rangeOfCharacter(from: globCharset) != nil else {
            return [pattern]
        }

        let paths = try? Path(pattern).glob()
        return paths?.compactMap { $0.description } ?? []
    }
}
