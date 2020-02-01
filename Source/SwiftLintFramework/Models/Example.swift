/// Captures code and context information for an example of a triggering or
/// non-triggering style
public struct Example {
    /// The contents of the example
    public var code: String

    // file and line are optional because we need to conform to
    // Codable, and StaticString isn't Codable, so we just ignore
    // them in Codable contexts.
    /// The path to the file where the example was created
    public var file: StaticString?
    /// The line in the file where the example was created
    public var line: UInt?
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

    /// Retunrs the same example, but with the `code` that is passed in
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

extension Example: Codable {
    private enum CodingKeys: CodingKey {
        case code
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.code = try container.decode(String.self, forKey: .code)

        // Can't encode/decode StaticString, but we don't need codable support
        // for this type in contexts where we are encoding and decoding anyway,
        // so let them stay as nil.
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(code, forKey: .code)
        // We don't care about encoding the file and line.
    }
}

extension Example: Comparable {
    public static func < (lhs: Example, rhs: Example) -> Bool {
        return lhs.code < rhs.code
    }
}
