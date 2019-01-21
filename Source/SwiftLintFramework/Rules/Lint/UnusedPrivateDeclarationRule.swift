import Foundation
import SourceKittenFramework

public struct UnusedPrivateDeclarationRule: AutomaticTestableRule, ConfigurationProviderRule, AnalyzerRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "unused_private_declaration",
        name: "Unused Private Declaration",
        description: "Private declarations should be referenced in that file.",
        kind: .lint,
        nonTriggeringExamples: [
            """
            private let kConstant = 0
            _ = kConstant
            """,
            """
            struct ResponseModel: Codable {
                let items: [Item]

                private enum CodingKeys: String, CodingKey {
                    case items = "ResponseItems"
                }
            }
            """,
            """
            class ResponseModel {
                @objc private func foo() {
                }
            }
            """
        ],
        triggeringExamples: [
            """
            private let ↓kConstant = 0
            """,
            """
            struct ResponseModel: Codable {
                let items: [Item]

                private enum ↓CodingKeys: String {
                    case items = "ResponseItems"
                }
            }
            """
        ],
        requiresFileOnDisk: true
    )

    public func validate(file: File, compilerArguments: [String]) -> [StyleViolation] {
        return violationOffsets(in: file, compilerArguments: compilerArguments).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: $0))
        }
    }

    private func violationOffsets(in file: File, compilerArguments: [String]) -> [Int] {
        guard !compilerArguments.isEmpty else {
            queuedPrintError("""
                Attempted to lint file at path '\(file.path ?? "...")' with the \
                \(type(of: self).description.identifier) rule without any compiler arguments.
                """)
            return []
        }

        let allCursorInfo = file.allCursorInfo(compilerArguments: compilerArguments)
        let privateDeclarationUSRs = File.declaredUSRs(allCursorInfo: allCursorInfo, acls: [.private, .fileprivate])
        let referencedUSRs = Set(File.referencedUSRs(allCursorInfo: allCursorInfo))
        let unusedPrivateDeclarations = privateDeclarationUSRs.filter { !referencedUSRs.contains($0.usr) }
        return unusedPrivateDeclarations.map { $0.nameOffset }
    }
}

// MARK: - File Extensions

private extension File {
    func allCursorInfo(compilerArguments: [String]) -> [[String: SourceKitRepresentable]] {
        guard let path = path, let editorOpen = try? Request.editorOpen(file: self).sendIfNotDisabled() else {
            return []
        }

        return syntaxMap.tokens.compactMap { token in
            let offset = Int64(token.offset)
            var cursorInfo = try? Request.cursorInfo(file: path, offset: offset,
                                                     arguments: compilerArguments).sendIfNotDisabled()
            if let acl = File.aclAtOffset(offset, substructureElement: editorOpen) {
                cursorInfo?["key.accessibility"] = acl
            }
            cursorInfo?["swiftlint.offset"] = offset
            return cursorInfo
        }
    }

    static func declaredUSRs(allCursorInfo: [[String: SourceKitRepresentable]],
                             acls: [AccessControlLevel]) -> [(usr: String, nameOffset: Int)] {
        return allCursorInfo.compactMap { declaredUSRAndOffset(cursorInfo: $0, acls: acls) }
    }

    static func referencedUSRs(allCursorInfo: [[String: SourceKitRepresentable]]) -> [String] {
        return allCursorInfo.compactMap(referencedUSR)
    }

    private static func declaredUSRAndOffset(cursorInfo: [String: SourceKitRepresentable],
                                             acls: [AccessControlLevel]) -> (usr: String, nameOffset: Int)? {
        if let offset = cursorInfo["swiftlint.offset"] as? Int64,
            let usr = cursorInfo["key.usr"] as? String,
            let kind = (cursorInfo["key.kind"] as? String).flatMap(SwiftDeclarationKind.init(rawValue:)),
            !declarationKindsToSkip.contains(kind),
            let acl = (cursorInfo["key.accessibility"] as? String).flatMap(AccessControlLevel.init(rawValue:)),
            acls.contains(acl) {
            // Skip declarations marked as @IBOutlet, @IBAction or @objc
            // since those might not be referenced in code, but only dynamically (e.g. Interface Builder)
            if let annotatedDecl = cursorInfo["key.annotated_decl"] as? String,
                ["@IBOutlet", "@IBAction", "@objc", "@IBInspectable"].contains(where: annotatedDecl.contains) {
                return nil
            }
            // Skip declarations that override another. This works for both subclass overrides &
            // protocol extension overrides.
            if cursorInfo["key.overrides"] != nil {
                return nil
            }

            // Skip CodingKeys as they are used
            if kind == .enum,
                cursorInfo.name == "CodingKeys",
                let annotatedDecl = cursorInfo["key.annotated_decl"] as? String,
                annotatedDecl.contains("usr=\"s:s9CodingKeyP\">CodingKey<") {
                return nil
            }
            return (usr, Int(offset))
        }

        return nil
    }

    private static func referencedUSR(cursorInfo: [String: SourceKitRepresentable]) -> String? {
        if let usr = cursorInfo["key.usr"] as? String,
            let kind = cursorInfo["key.kind"] as? String,
            kind.contains("source.lang.swift.ref") {
            return usr
        }

        return nil
    }

    private static func aclAtOffset(_ offset: Int64, substructureElement: [String: SourceKitRepresentable]) -> String? {
        if let nameOffset = substructureElement["key.nameoffset"] as? Int64,
            nameOffset == offset,
            let acl = substructureElement["key.accessibility"] as? String {
            return acl
        }
        if let substructure = substructureElement[SwiftDocKey.substructure.rawValue] as? [SourceKitRepresentable] {
            let nestedSubstructure = substructure.compactMap({ $0 as? [String: SourceKitRepresentable] })
            for child in nestedSubstructure {
                if let acl = File.aclAtOffset(offset, substructureElement: child) {
                    return acl
                }
            }
        }
        return nil
    }
}

// Skip initializers, deinit, enum cases and subscripts since we can't reliably detect if they're used.
private let declarationKindsToSkip: Set<SwiftDeclarationKind> = [
    .functionConstructor,
    .functionDestructor,
    .enumelement,
    .functionSubscript
]
