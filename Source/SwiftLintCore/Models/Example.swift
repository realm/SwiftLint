import Foundation

/// Captures code and context information for an example of a triggering or
/// non-triggering style
public struct Example: Sendable {
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
    public private(set) var configuration: [String: any Sendable]?
    /// Whether the example should be tested by prepending multibyte grapheme clusters
    ///
    /// - SeeAlso: addEmoji(_:)
    public private(set) var testMultiByteOffsets: Bool
    /// Whether tests shall verify that the example wrapped in a comment doesn't trigger
    package private(set) var testWrappingInComment: Bool
    /// Whether tests shall verify that the example wrapped into a string doesn't trigger
    package private(set) var testWrappingInString: Bool
    /// Whether tests shall verify that the disabled rule (comment in the example) doesn't trigger
    package private(set) var testDisableCommand: Bool
    /// Whether the example should be tested on Linux
    public private(set) var testOnLinux: Bool
    /// Whether the example should be tested on Windows
    public private(set) var testOnWindows: Bool
    /// The ID of the file in which the example was created
    public private(set) var fileID: String
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
    package var excludeFromDocumentation: Bool

    /// Specifies whether the test example should be the only example run during the current test case execution.
    package var isFocused: Bool
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
    ///   - fileID:               ID of the file in which the example is located.
    ///   - file:                 The path to the file where the example is located.
    ///                           Defaults to the file where this initializer is called.
    ///   - line:                 The line in the file where the example is located.
    ///                           Defaults to the line where this initializer is called.
    init(_ code: String,
         configuration: [String: any Sendable]? = nil,
         testMultiByteOffsets: Bool = true,
         testWrappingInComment: Bool = true,
         testWrappingInString: Bool = true,
         testDisableCommand: Bool = true,
         testOnLinux: Bool = true,
         testOnWindows: Bool = true,
         fileID: String = #fileID,
         file: StaticString = #filePath,
         line: UInt = #line,
         excludeFromDocumentation: Bool = false) {
        self.code = code
        self.configuration = configuration
        self.testMultiByteOffsets = testMultiByteOffsets
        self.testOnLinux = testOnLinux
        self.testOnWindows = testOnWindows
        self.fileID = fileID
        self.file = file
        self.line = line
        self.excludeFromDocumentation = excludeFromDocumentation
        self.testWrappingInComment = testWrappingInComment
        self.testWrappingInString = testWrappingInString
        self.testDisableCommand = testDisableCommand
        self.isFocused = false
    }

    /// Convenience init so that arrays can mix string literals with concrete `Example`s,
    /// and still get the right file and line information. Used by the `#examples` macro to
    /// re-capture the file and line of each element at its call site.
    init(
        _ other: Example,
        fileID: String = #fileID,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        var new = other
        new.fileID = fileID
        new.file = file
        new.line = line
        self = new
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
        with(code: code.replacingOccurrences(of: "↓", with: ""))
    }

    /// Returns the same example, optionally excluded from the rule documentation.
    func excludeFromDocumentation(_ value: Bool = true) -> Self {
        var copy = self
        copy.excludeFromDocumentation = value
        return copy
    }

    /// Returns the same example, but with the given rule configuration applied.
    func configuration(_ value: [String: any Sendable]?) -> Self {
        var copy = self
        copy.configuration = value
        return copy
    }
}

public extension Example {
    /// Returns the same example, but configured to skip the test that wraps it in a comment.
    func skipWrappingInCommentTest() -> Self {
        var new = self
        new.testWrappingInComment = false
        return new
    }

    /// Returns the same example, but configured to skip the test that wraps it in a string.
    func skipWrappingInStringTest() -> Self {
        var new = self
        new.testWrappingInString = false
        return new
    }

    /// Returns the same example, but configured to skip the multi-byte offset test.
    func skipMultiByteOffsetTest() -> Self {
        var new = self
        new.testMultiByteOffsets = false
        return new
    }

    /// Returns the same example, but configured to skip the disable-command test.
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

public extension String {
    /// Wraps this code in an `Example`, optionally excluding it from the rule documentation.
    func excludeFromDocumentation(
        _ excludeFromDocumentation: Bool = true,
        fileID: String = #fileID,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Example {
        Example(self, fileID: fileID, file: file, line: line)
            .excludeFromDocumentation(excludeFromDocumentation)
    }

    /// Wraps this code in an `Example` that applies the given rule configuration.
    func configuration(
        _ configuration: [String: any Sendable],
        fileID: String = #fileID,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Example {
        Example(self, fileID: fileID, file: file, line: line)
            .configuration(configuration)
    }

    /// Wraps this code in an `Example` that skips the wrap-in-comment test.
    func skipWrappingInCommentTest(
        fileID: String = #fileID,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Example {
        Example(self, fileID: fileID, file: file, line: line)
            .skipWrappingInCommentTest()
    }

    /// Wraps this code in an `Example` that skips the wrap-in-string test.
    func skipWrappingInStringTest(
        fileID: String = #fileID,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Example {
        Example(self, fileID: fileID, file: file, line: line)
            .skipWrappingInStringTest()
    }

    /// Wraps this code in an `Example` that skips the multi-byte offset test.
    func skipMultiByteOffsetTest(
        fileID: String = #fileID,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Example {
        Example(self, fileID: fileID, file: file, line: line)
            .skipMultiByteOffsetTest()
    }

    /// Wraps this code in an `Example` that skips the disable-command test.
    func skipDisableCommandTest(
        fileID: String = #fileID,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Example {
        Example(self, fileID: fileID, file: file, line: line)
            .skipDisableCommandTest()
    }
}

extension Example: Hashable {
    public static func == (lhs: Example, rhs: Example) -> Bool {
        // Ignoring file/line metadata because two Examples could represent
        // the same idea, but captured at two different points in the code
        lhs.code == rhs.code
            && lhs.configuration?.mapValues(String.init(describing:))
                == rhs.configuration?.mapValues(String.init(describing:))
    }

    public func hash(into hasher: inout Hasher) {
        // Ignoring file/line metadata because two Examples could represent
        // the same idea, but captured at two different points in the code
        hasher.combine(code)
        hasher.combine(configuration?.mapValues(String.init(describing:)))
    }
}

extension Example: Comparable {
    public static func < (lhs: Example, rhs: Example) -> Bool {
        lhs.code < rhs.code
    }
}

public extension Array where Element == Example {
    /// Make these examples skip wrapping in comment tests.
    func skipWrappingInCommentTests() -> Self {
        map { $0.skipWrappingInCommentTest() }
    }

    /// Make these examples skip wrapping in string tests.
    func skipWrappingInStringTests() -> Self {
        map { $0.skipWrappingInStringTest() }
    }

    /// Make these examples skip multi-byte offset tests.
    func skipMultiByteOffsetTests() -> Self {
        map { $0.skipMultiByteOffsetTest() }
    }

    /// Make these examples skip disable command tests.
    func skipDisableCommandTests() -> Self {
        map { $0.skipDisableCommandTest() }
    }

    /// Remove all violation markers from the examples.
    func removingViolationMarker() -> Self {
        map { $0.removingViolationMarkers() }
    }
}
