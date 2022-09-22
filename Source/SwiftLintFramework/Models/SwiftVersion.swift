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
    /// Swift 5.7.x - https://swift.org/download/#swift-57
    static let fiveDotSeven = SwiftVersion(rawValue: "5.7.0")

    /// The current detected Swift compiler version, based on the currently accessible SourceKit version.
    ///
    /// - note: Override by setting the `SWIFTLINT_SWIFT_VERSION` environment variable.
    static let current: SwiftVersion = {
        // Allow forcing the Swift version, useful in cases where SourceKit isn't available
        if let envVersion = ProcessInfo.processInfo.environment["SWIFTLINT_SWIFT_VERSION"] {
            switch envVersion {
            case "5":
                return .five
            default:
                return .five
            }
        }

        if !Request.disableSourceKit {
            // This request was added in Swift 5.1
            let params: SourceKitObject = ["key.request": UID("source.request.compiler_version")]
            if let result = try? Request.customRequest(request: params).send(),
                let major = result.versionMajor, let minor = result.versionMinor, let patch = result.versionPatch {
                return SwiftVersion(rawValue: "\(major).\(minor).\(patch)")
            }
        }

        return .five
    }()
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
