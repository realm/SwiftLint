extension String {
    /// Trims all whitespace from a string
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
