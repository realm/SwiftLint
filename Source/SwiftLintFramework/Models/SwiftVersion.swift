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

    /// The current detected Swift compiler version, based on the currently accessible SourceKit version.
    ///
    /// - note: Override by setting the `SWIFTLINT_SWIFT_VERSION` environment variable.
    static let current: SwiftVersion = {
        // Allow forcing the Swift version, useful in cases where SourceKit isn't available
        if let envVersion = ProcessInfo.processInfo.environment["SWIFTLINT_SWIFT_VERSION"] {
            switch envVersion {
            case "5":
                return .five
            case "4":
                return .four
            default:
                return .three
            }
        }

        if !Request.disableSourceKit {
            let params: SourceKitObject = ["key.request": UID("source.request.compiler_version")]
            if let result = try? Request.customRequest(request: params).send(),
                let major = result.versionMajor, let minor = result.versionMinor, let patch = result.versionPatch {
                return SwiftVersion(rawValue: "\(major).\(minor).\(patch)")
            }
        }

        if !Request.disableSourceKit,
            case let dynamicCallableFile = SwiftLintFile(contents: "@dynamicCallable"),
            dynamicCallableFile.syntaxMap.tokens.compactMap({ $0.kind }) == [.attributeID] {
            return .five
        }

        let file = SwiftLintFile(contents: """
            #if swift(>=4.2.0)
                let version = "4.2.0"
            #elseif swift(>=4.1.50)
                let version = "4.1.50"
            #elseif swift(>=4.1.2)
                let version = "4.1.2"
            #elseif swift(>=4.1.1)
                let version = "4.1.1"
            #elseif swift(>=4.1.0)
                let version = "4.1.0"
            #elseif swift(>=4.0.3)
                let version = "4.0.3"
            #elseif swift(>=4.0.2)
                let version = "4.0.2"
            #elseif swift(>=4.0.1)
                let version = "4.0.1"
            #elseif swift(>=4.0.0)
                let version = "4.0.0"
            #elseif swift(>=3.4.0)
                let version = "3.4.0"
            #elseif swift(>=3.3.2)
                let version = "3.3.2"
            #elseif swift(>=3.3.1)
                let version = "3.3.1"
            #elseif swift(>=3.3.0)
                let version = "3.3.0"
            #elseif swift(>=3.2.3)
                let version = "3.2.3"
            #elseif swift(>=3.2.2)
                let version = "3.2.2"
            #elseif swift(>=3.2.1)
                let version = "3.2.1"
            #elseif swift(>=3.2.0)
                let version = "3.2.0"
            #elseif swift(>=3.1.1)
                let version = "3.1.1"
            #elseif swift(>=3.1.0)
                let version = "3.1.0"
            #elseif swift(>=3.0.2)
                let version = "3.0.2"
            #elseif swift(>=3.0.1)
                let version = "3.0.1"
            #elseif swift(>=3.0.0)
                let version = "3.0.0"
            #endif
            """)
        if !Request.disableSourceKit,
            let decl = file.structureDictionary.kinds()
                .first(where: { $0.kind == SwiftDeclarationKind.varGlobal.rawValue }),
            let token = file.syntaxMap.tokens(inByteRange: decl.byteRange).first(where: { $0.kind == .string }) {
            let offsetRange = ByteRange(location: token.offset + 1, length: token.length - 2)
            return .init(rawValue: file.stringView.substringWithByteRange(offsetRange)!)
        }

        return .three
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
