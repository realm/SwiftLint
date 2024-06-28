/// A type describing the SwiftLint version.
public struct Version {
    /// The string value for this version.
    public let value: String

    /// The current SwiftLint version.
    public static let current = Version(value: "0.55.1")

    /// Public initializer.
    ///
    /// - parameter value: The string value for this version.
    public init(value: String) {
        self.value = value
    }
}

extension Version: Comparable {
    public static func == (lhs: Version, rhs: Version) -> Bool {
        lhs.value == rhs.value
    }

    public static func < (lhs: Version, rhs: Version) -> Bool {
        if let lhsComparators = lhs.comparators, let rhsComparators = rhs.comparators {
            return lhsComparators.lexicographicallyPrecedes(rhsComparators)
        }
        return lhs.value < rhs.value
    }

    private var comparators: [Int]? {
        let components = value.split(separator: ".").compactMap { Int($0) }
        guard let major = components.first else {
            return nil
        }
        let minor = components.dropFirst(1).first ?? 0
        let patch = components.dropFirst(2).first ?? 0
        return [major, minor, patch]
    }
}
