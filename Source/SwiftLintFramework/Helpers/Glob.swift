import Foundation
import Pathos

struct Glob {
    static func resolveGlob(_ pattern: String) -> [String] {
        let globCharset = CharacterSet(charactersIn: "*?[]")
        guard pattern.rangeOfCharacter(from: globCharset) != nil else {
            return [pattern]
        }

        do {
            let paths = try Path(pattern).glob()
            return try paths.compactMap { path in
                try path.absolute().description
            }
        } catch {
            queuedPrintError(error.localizedDescription)
            return []
        }
    }
}
