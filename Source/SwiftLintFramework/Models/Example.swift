/// Captures code and context information for an example of a triggering or
/// non-triggering style
public struct Example {
    /// The contents of the example
    public private(set) var code: String
    /// The path to the file where the example was created
    public private(set) var file: StaticString
    /// The line in the file where the example was created
    public var line: UInt
}

public extension Example {
    /// Create a new Example with the specified code, file, and line
    /// - Parameters:
    ///   - code: The contents of the example
    ///   - file: The path to the file where the example is located.
    ///           Defaults to the file where this initializer is called.
    ///   - line: The line in the file where the example is located.
    ///           Defaults to the line where this initializer is called.
    init(_ code: String, file: StaticString = #file, line: UInt = #line) {
        self.code = code
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
