extension String {
    var formattedAsStringLiteral: String {
        return "\"" + replacingOccurrences(of: "\n", with: "\\n") + "\""
    }

    func stringByAppendingPathComponent(_ pathComponent: String) -> String {
        return bridge().appendingPathComponent(pathComponent)
    }
}
