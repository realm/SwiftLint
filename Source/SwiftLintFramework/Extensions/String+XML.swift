extension String {
    /// Escapes `&`, `"`, `'`, `>` and `<`, and replaces each character that XML 1.0 cannot hold at all, not even as
    /// a character reference, with U+FFFD REPLACEMENT CHARACTER: the C0 controls other than tab, line feed and
    /// carriage return, plus U+FFFE and U+FFFF.
    ///
    /// Works on Unicode scalars rather than `Character`s, because `<` followed by a combining mark is a single
    /// `Character` that is not equal to `<`, so a `Character`-based replacement would write the `<` raw.
    func escapedForXML() -> String {
        var escaped = ""
        escaped.reserveCapacity(utf8.count)
        for scalar in unicodeScalars {
            switch scalar {
            case "&": escaped += "&amp;"
            case "\"": escaped += "&quot;"
            case "'": escaped += "&apos;"
            case ">": escaped += "&gt;"
            case "<": escaped += "&lt;"
            case "\t", "\n", "\r": escaped.unicodeScalars.append(scalar)
            case "\u{0}"..."\u{1F}", "\u{FFFE}", "\u{FFFF}": escaped += "\u{FFFD}"
            default: escaped.unicodeScalars.append(scalar)
            }
        }
        return escaped
    }
}
