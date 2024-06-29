/// A type describing the SwiftLint version.
public struct Version: VersionComparable {
    /// The string value for this version.
    public let value: String

    public var rawValue: String {
        value
    }

    /// The current SwiftLint version.
    public static let current = Version(value: "0.55.1")

    /// Public initializer.
    ///
    /// - parameter value: The string value for this version.
    public init(value: String) {
        self.value = value
    }
}
