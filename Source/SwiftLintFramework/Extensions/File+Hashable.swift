import SourceKittenFramework

extension File: Hashable {
    public static func == (lhs: File, rhs: File) -> Bool {
        switch (lhs.path, rhs.path) {
        case let (.some(lhsPath), .some(rhsPath)):
            return lhsPath == rhsPath
        case (.none, .none):
            return lhs.contents == rhs.contents
        default:
            return false
        }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(path ?? contents)
    }
}
