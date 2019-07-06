import Foundation
import SourceKittenFramework

public struct SwiftVersion: RawRepresentable, Codable {
    public typealias RawValue = String

    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

extension SwiftVersion: Comparable {
    // Comparable
    public static func < (lhs: SwiftVersion, rhs: SwiftVersion) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

public extension SwiftVersion {
    static let three = SwiftVersion(rawValue: "3.0.0")
    static let four = SwiftVersion(rawValue: "4.0.0")
    static let fourDotOne = SwiftVersion(rawValue: "4.1.0")
    static let fourDotTwo = SwiftVersion(rawValue: "4.2.0")
    static let five = SwiftVersion(rawValue: "5.0.0")
    static let fiveDotOne = SwiftVersion(rawValue: "5.1.0")

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
            case let dynamicCallableFile = File(contents: "@dynamicCallable"),
            dynamicCallableFile.syntaxMap.tokens.compactMap({ SyntaxKind(rawValue: $0.type) }) == [.attributeID] {
            return .five
        }

        let file = File(contents: """
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
        func isString(token: SyntaxToken) -> Bool {
            return token.type == SyntaxKind.string.rawValue
        }
        if !Request.disableSourceKit,
            let decl = file.structure.kinds().first(where: { $0.kind == SwiftDeclarationKind.varGlobal.rawValue }),
            let token = file.syntaxMap.tokens(inByteRange: decl.byteRange).first(where: isString ) {
            return .init(rawValue: file.contents.substring(from: token.offset + 1, length: token.length - 2))
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
