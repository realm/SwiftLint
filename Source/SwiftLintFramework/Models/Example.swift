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
    /// Whether tests shall verify that the example wrapped in a comment doesn't trigger
    private(set) var testWrappingInComment: Bool
    /// Whether tests shall verify that the example wrapped into a string doesn't trigger
    private(set) var testWrappingInString: Bool
    /// Whether tests shall verify that the disabled rule (comment in the example) doesn't trigger
    private(set) var testDisableCommand: Bool
    /// Whether the example should be tested on Linux
    public private(set) var testOnLinux: Bool
    /// The path to the file where the example was created
    public private(set) var file: StaticString
    /// The line in the file where the example was created
    public var line: UInt
    /// Specifies whether the example should be excluded from the rule documentation.
    ///
    /// It can be set to `true` if an example has mainly been added as another test case, but is not suitable
    /// as a user example. User examples should be easy to understand. They should clearly show where and
    /// why a rule is applied and where not. Complex examples with rarely used language constructs or
    /// pathological use cases which are indeed important to test but not helpful for understanding can be
    /// hidden from the documentation with this option.
    let excludeFromDocumentation: Bool

    /// Specifies whether the test example should be the only example run during the current test case execution.
    var isFocused: Bool
}

public extension Example {
    /// Create a new Example with the specified code, file, and line.
    /// - Parameters:
    ///   - code:                 The contents of the example.
    ///   - configuration:        The untyped configuration to apply to the rule, if deviating from the default
    ///                           configuration.
    ///   - testMultibyteOffsets: Whether the example should be tested by prepending multibyte grapheme clusters.
    ///   - testWrappingInComment:Whether test shall verify that the example wrapped in a comment doesn't trigger.
    ///   - testWrappingInString: Whether tests shall verify that the example wrapped into a string doesn't trigger.
    ///   - testDisableCommand:   Whether tests shall verify that the disabled rule (comment in the example) doesn't
    ///                           trigger.
    ///   - testOnLinux:          Whether the example should be tested on Linux.
    ///   - file:                 The path to the file where the example is located.
    ///                           Defaults to the file where this initializer is called.
    ///   - line:                 The line in the file where the example is located.
    ///                           Defaults to the line where this initializer is called.
    init(_ code: String, configuration: Any? = nil, testMultiByteOffsets: Bool = true,
         testWrappingInComment: Bool = true, testWrappingInString: Bool = true, testDisableCommand: Bool = true,
         testOnLinux: Bool = true, file: StaticString = #file, line: UInt = #line,
         excludeFromDocumentation: Bool = false) {
        self.code = code
        self.configuration = configuration
        self.testMultiByteOffsets = testMultiByteOffsets
        self.testOnLinux = testOnLinux
        self.file = file
        self.line = line
        self.excludeFromDocumentation = excludeFromDocumentation
        self.testWrappingInComment = testWrappingInComment
        self.testWrappingInString = testWrappingInString
        self.testDisableCommand = testDisableCommand
        self.isFocused = false
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

extension Example {
    func skipWrappingInCommentTest() -> Self {
        var new = self
        new.testWrappingInComment = false
        return new
    }

    func skipWrappingInStringTest() -> Self {
        var new = self
        new.testWrappingInString = false
        return new
    }

    func skipMultiByteOffsetTest() -> Self {
        var new = self
        new.testMultiByteOffsets = false
        return new
    }

    func skipDisableCommandTest() -> Self {
        var new = self
        new.testDisableCommand = false
        return new
    }

    /// Makes the current example focused. This is for debugging purposes only.
    func focused() -> Example { // swiftlint:disable:this unused_declaration
        var new = self
        new.isFocused = true
        return new
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

extension Array where Element == Example {
    func skipWrappingInCommentTests() -> Self {
        map { $0.skipWrappingInCommentTest() }
    }

    func skipWrappingInStringTests() -> Self {
        map { $0.skipWrappingInStringTest() }
    }

    func skipMultiByteOffsetTests() -> Self {
        map { $0.skipMultiByteOffsetTest() }
    }

    func skipDisableCommandTests() -> Self {
        map { $0.skipDisableCommandTest() }
    }
}
