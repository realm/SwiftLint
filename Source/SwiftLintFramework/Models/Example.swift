/// Captures code and context information for an example of a triggering or
/// non-triggering style
public struct Example {
    /// The contents of the example
    public private(set) var code: String
    /// The untyped configuration to apply to the rule, if deviating from the default configuration.
    /// The structure should match what is expected as a configuration value for the rule being tested.
    ///
    /// For example, if the following YAML would be used to configure the rule:
    ///
    /// ```
    /// severity: warning
    /// ```
    ///
    /// Then the equivalent configuration value would be `["severity": "warning"]`.
    public private(set) var configuration: Any?
    /// Whether the example should be tested by prepending multibyte grapheme clusters
    ///
    /// - SeeAlso: addEmoji(_:)
    public private(set) var testMultiByteOffsets: Bool
    /// Whether the example should be tested on Linux
    public private(set) var testOnLinux: Bool
    /// The path to the file where the example was created
    public private(set) var file: StaticString
    /// The line in the file where the example was created
    public var line: UInt
}

public extension Example {
    /// Create a new Example with the specified code, file, and line.
    /// - Parameters:
    ///   - code:                 The contents of the example.
    ///   - configuration:        The untyped configuration to apply to the rule, if deviating from the default
    ///                           configuration.
    ///   - testMultibyteOffsets: Whether the example should be tested by prepending multibyte grapheme clusters.
    ///   - testOnLinux:          Whether the example should be tested on Linux.
    ///   - file:                 The path to the file where the example is located.
    ///                           Defaults to the file where this initializer is called.
    ///   - line:                 The line in the file where the example is located.
    ///                           Defaults to the line where this initializer is called.
    init(_ code: String, configuration: Any? = nil, testMultiByteOffsets: Bool = true, testOnLinux: Bool = true,
         file: StaticString = #file, line: UInt = #line) {
        self.code = code
        self.configuration = configuration
        self.testMultiByteOffsets = testMultiByteOffsets
        self.testOnLinux = testOnLinux
        self.file = file
        self.line = line
    }

    /// Returns the same example, but with the `code` that is passed in
    /// - Parameter code: the new code to use in the modified example
    func with(code: String) -> Example {
        var new = self
        new.code = code
        return new
    }

    /// Returns a copy of the Example with all instances of the "↓" character removed.
    func removingViolationMarkers() -> Example {
        return with(code: code.replacingOccurrences(of: "↓", with: ""))
    }
}

extension Example: Hashable {
    public static func == (lhs: Example, rhs: Example) -> Bool {
        // Ignoring file/line metadata because two Examples could represent
        // the same idea, but captured at two different points in the code
        return lhs.code == rhs.code
    }

    public func hash(into hasher: inout Hasher) {
        // Ignoring file/line metadata because two Examples could represent
        // the same idea, but captured at two different points in the code
        hasher.combine(code)
    }
}

extension Example: Comparable {
    public static func < (lhs: Example, rhs: Example) -> Bool {
        return lhs.code < rhs.code
    }
}
