import Foundation
import SourceKittenFramework

public struct SwiftLintSyntaxToken {
    public let value: SyntaxToken
    public let kind: SyntaxKind?

    public init(value: SyntaxToken) {
        self.value = value
        kind = SyntaxKind(rawValue: value.type)
    }

    public var range: NSRange {
        return NSRange(location: value.offset, length: value.length)
    }

    public var offset: Int {
        return value.offset
    }

    public var length: Int {
        return value.length
    }
}

extension Array where Element == SwiftLintSyntaxToken {
    var kinds: [SyntaxKind] {
        return compactMap { $0.kind }
    }
}
