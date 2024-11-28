import Foundation
import SourceKittenFramework

/// A value describing the version of the Swift compiler.
public struct SwiftVersion: RawRepresentable, Codable, VersionComparable, Sendable {
    public typealias RawValue = String

    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

/// A comparable `major.minor.patch` version number.
public protocol VersionComparable: Comparable {
    /// The version string.
    var rawValue: String { get }
}

extension VersionComparable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        if let lhsComparators = lhs.comparators, let rhsComparators = rhs.comparators {
            return lhsComparators == rhsComparators
        }
        return lhs.rawValue == rhs.rawValue
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        if let lhsComparators = lhs.comparators, let rhsComparators = rhs.comparators {
            return lhsComparators.lexicographicallyPrecedes(rhsComparators)
        }
        return lhs.rawValue < rhs.rawValue
    }

    private var comparators: [Int]? {
        let components = rawValue.split(separator: ".").compactMap { Int($0) }
        guard let major = components.first else {
            return nil
        }
        let minor = components.dropFirst(1).first ?? 0
        let patch = components.dropFirst(2).first ?? 0
        return [major, minor, patch]
    }
}

public extension SwiftVersion {
    /// Swift 5
    static let five = SwiftVersion(rawValue: "5.0.0")
    /// Swift 5.1
    static let fiveDotOne = SwiftVersion(rawValue: "5.1.0")
    /// Swift 5.2
    static let fiveDotTwo = SwiftVersion(rawValue: "5.2.0")
    /// Swift 5.3
    static let fiveDotThree = SwiftVersion(rawValue: "5.3.0")
    /// Swift 5.4
    static let fiveDotFour = SwiftVersion(rawValue: "5.4.0")
    /// Swift 5.5
    static let fiveDotFive = SwiftVersion(rawValue: "5.5.0")
    /// Swift 5.6
    static let fiveDotSix = SwiftVersion(rawValue: "5.6.0")
    /// Swift 5.7
    static let fiveDotSeven = SwiftVersion(rawValue: "5.7.0")
    /// Swift 5.8
    static let fiveDotEight = SwiftVersion(rawValue: "5.8.0")
    /// Swift 5.9
    static let fiveDotNine = SwiftVersion(rawValue: "5.9.0")
    /// Swift 6
    static let six = SwiftVersion(rawValue: "6.0.0")

    /// The current detected Swift compiler version, based on the currently accessible SourceKit version.
    ///
    /// - note: Override by setting the `SWIFTLINT_SWIFT_VERSION` environment variable.
    static let current: SwiftVersion = {
        // Allow forcing the Swift version, useful in cases where SourceKit isn't available.
        if let envVersion = ProcessInfo.processInfo.environment["SWIFTLINT_SWIFT_VERSION"] {
            return SwiftVersion(rawValue: envVersion)
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
        (self["key.version_major"] as? Int64).flatMap({ Int($0) })
    }

    var versionMinor: Int? {
        (self["key.version_minor"] as? Int64).flatMap({ Int($0) })
    }

    var versionPatch: Int? {
        (self["key.version_patch"] as? Int64).flatMap({ Int($0) })
    }
}
