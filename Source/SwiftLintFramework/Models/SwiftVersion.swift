import Foundation
import SourceKittenFramework

/// A value describing the version of the Swift compiler.
public struct SwiftVersion: RawRepresentable, Codable, Comparable {
    public typealias RawValue = String

    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static func < (lhs: SwiftVersion, rhs: SwiftVersion) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

public extension SwiftVersion {
    /// Swift 3.x - https://swift.org/download/#swift-30
    static let three = SwiftVersion(rawValue: "3.0.0")
    /// Swift 4.0.x - https://swift.org/download/#swift-40
    static let four = SwiftVersion(rawValue: "4.0.0")
    /// Swift 4.1.x - https://swift.org/download/#swift-41
    static let fourDotOne = SwiftVersion(rawValue: "4.1.0")
    /// Swift 4.2.x - https://swift.org/download/#swift-42
    static let fourDotTwo = SwiftVersion(rawValue: "4.2.0")
    /// Swift 5.0.x - https://swift.org/download/#swift-50
    static let five = SwiftVersion(rawValue: "5.0.0")
    /// Swift 5.1.x - https://swift.org/download/#swift-51
    static let fiveDotOne = SwiftVersion(rawValue: "5.1.0")
    /// Swift 5.2.x - https://swift.org/download/#swift-52
    static let fiveDotTwo = SwiftVersion(rawValue: "5.2.0")
    /// Swift 5.3.x - https://swift.org/download/#swift-53
    static let fiveDotThree = SwiftVersion(rawValue: "5.3.0")
    /// Swift 5.4.x - https://swift.org/download/#swift-54
    static let fiveDotFour = SwiftVersion(rawValue: "5.4.0")
    /// Swift 5.5.x - https://swift.org/download/#swift-55
    static let fiveDotFive = SwiftVersion(rawValue: "5.5.0")
    /// Swift 5.6.x - https://swift.org/download/#swift-56
    static let fiveDotSix = SwiftVersion(rawValue: "5.6.0")

    /// The current detected Swift compiler version, based on the currently accessible SourceKit version.
    ///
    /// - note: Override by setting the `SWIFTLINT_SWIFT_VERSION` environment variable.
    static let current: SwiftVersion = { .fiveDotFive }()
}

private extension Dictionary where Key == String {
    var versionMajor: Int? {
        return (self["key.version_major"] as? Int64).flatMap({ Int($0) })
    }

    var versionMinor: Int? {
        return (self["key.version_minor"] as? Int64).flatMap({ Int($0) })
    }

    var versionPatch: Int? {
        return (self["key.version_patch"] as? Int64).flatMap({ Int($0) })
    }
}
