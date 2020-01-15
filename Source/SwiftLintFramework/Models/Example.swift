/// Captures code and context information for an example of a triggering or
/// non-triggering style
public struct Example {
    public var code: String

    // TODO: unoptionalize these parameters
    // Using String instead of StaticString for Codable conformance
    public var file: StaticString?
    public var line: UInt?
}

public extension Example {
    init(_ code: String, file: StaticString = #file, line: UInt = #line) {
        self.code = code
        self.file = file
        self.line = line
    }

    func with(code: String) -> Example {
        var new = self
        new.code = code
        return new
    }

    func removingViolationMarkers() -> Example {
        return with(code: code.replacingOccurrences(of: "↓", with: ""))
    }
}

extension Example: Hashable {
    public static func == (lhs: Example, rhs: Example) -> Bool {
        // Ignoring file/line metadata beacuse two Examples could represent
        // the same idea, but captured at two different points in the code
        return lhs.code == rhs.code
    }

    public func hash(into hasher: inout Hasher) {
        // Ignoring file/line metadata beacuse two Examples could represent
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

// TODO: remove this conformance. It's a band-aid so I didn't have to wrap every
// string in Example(...) just to get this working
// Also, this initializer is called all the time because  of a Swift bug:
// https://bugs.swift.org/browse/SR-12034. So we need to call
// Example.init("foo") in the places we actually want the other initializer to
// run. Fortunately, it's all moot once we delete this conformance.
extension Example: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.code = value
        self.file = nil
        self.line = nil
    }
}

extension Example: Comparable {
    public static func < (lhs: Example, rhs: Example) -> Bool {
        return lhs.code < rhs.code
    }
}
