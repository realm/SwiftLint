/// A type describing the SwiftLint version.
public struct Version {
    /// The string value for this version.
    public let value: String

    /// The current SwiftLint version.
    public static let current = Self(value: "0.50.3")
}
