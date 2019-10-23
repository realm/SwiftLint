import Foundation
import SourceKittenFramework

public struct UnusedDeclarationRule: AutomaticTestableRule, ConfigurationProviderRule, AnalyzerRule, CollectingRule {
    public struct FileUSRs {
        var referenced: Set<String>
        var declared: [(usr: String, nameOffset: Int)]
        var testCaseUSRs: Set<String>
    }

    public typealias FileInfo = FileUSRs

    public var configuration = UnusedDeclarationConfiguration(severity: .error, includePublicAndOpen: false)

    public init() {}

    public static let description = RuleDescription(
        identifier: "unused_declaration",
        name: "Unused Declaration",
        description: "Declarations should be referenced at least once within all files linted.",
        kind: .lint,
        nonTriggeringExamples: [
            """
            let kConstant = 0
            _ = kConstant
            """,
            """
            struct Item {}
            struct ResponseModel: Codable {
                let items: [Item]

                enum CodingKeys: String, CodingKey {
                    case items = "ResponseItems"
                }
            }

            _ = ResponseModel(items: [Item()]).items
            """,
            """
            class ResponseModel {
                @objc func foo() {
                }
            }
            _ = ResponseModel()
            """
        ],
        triggeringExamples: [
            """
            let ↓kConstant = 0
            """,
            """
            struct Item {}
            struct ↓ResponseModel: Codable {
                let ↓items: [Item]

                enum ↓CodingKeys: String {
                    case items = "ResponseItems"
                }
            }
            """,
            """
            class ↓ResponseModel {
                func ↓foo() {
                }
            }
            """
        ],
        requiresFileOnDisk: true
    )

    public func collectInfo(for file: File, compilerArguments: [String]) -> UnusedDeclarationRule.FileUSRs {
        guard !compilerArguments.isEmpty else {
            queuedPrintError("""
                Attempted to lint file at path '\(file.path ?? "...")' with the \
                \(type(of: self).description.identifier) rule without any compiler arguments.
                """)
            return FileUSRs(referenced: [], declared: [], testCaseUSRs: [])
        }

        let allCursorInfo = file.allCursorInfo(compilerArguments: compilerArguments)
        return FileUSRs(referenced: Set(File.referencedUSRs(allCursorInfo: allCursorInfo)),
                        declared: File.declaredUSRs(allCursorInfo: allCursorInfo,
                                                    includePublicAndOpen: configuration.includePublicAndOpen),
                        testCaseUSRs: File.testCaseUSRs(allCursorInfo: allCursorInfo))
    }

    public func validate(file: File, collectedInfo: [File: UnusedDeclarationRule.FileUSRs],
                         compilerArguments: [String]) -> [StyleViolation] {
        let allReferencedUSRs = collectedInfo.values.reduce(into: Set()) { $0.formUnion($1.referenced) }
        let allTestCaseUSRs = collectedInfo.values.reduce(into: Set()) { $0.formUnion($1.testCaseUSRs) }
        return violationOffsets(in: file, compilerArguments: compilerArguments,
                                declaredUSRs: collectedInfo[file]?.declared ?? [],
                                allReferencedUSRs: allReferencedUSRs,
                                allTestCaseUSRs: allTestCaseUSRs)
            .map {
                StyleViolation(ruleDescription: type(of: self).description,
                               severity: configuration.severity,
                               location: Location(file: file, byteOffset: $0))
            }
    }

    private func violationOffsets(in file: File, compilerArguments: [String],
                                  declaredUSRs: [(usr: String, nameOffset: Int)],
                                  allReferencedUSRs: Set<String>,
                                  allTestCaseUSRs: Set<String>) -> [Int] {
        // Unused declarations are:
        // 1. all declarations
        // 2. minus all references
        // 3. minus all XCTestCase subclasses
        // 4. minus all XCTest test functions
        let unusedDeclarations = declaredUSRs
            .filter { !allReferencedUSRs.contains($0.usr) }
            .filter { !allTestCaseUSRs.contains($0.usr) }
            .filter { declaredUSR in
                return !allTestCaseUSRs.contains(where: { testCaseUSR in
                    return declaredUSR.usr.hasPrefix(testCaseUSR + "(im)test") ||
                        declaredUSR.usr.hasPrefix(
                            testCaseUSR.replacingOccurrences(of: "@M@", with: "@CM@") + "(im)test"
                        )
                })
            }
        return unusedDeclarations.map { $0.nameOffset }
    }
}

// MARK: - File Extensions

private extension File {
    func allCursorInfo(compilerArguments: [String]) -> [[String: SourceKitRepresentable]] {
        guard let path = path, let editorOpen = try? Request.editorOpen(file: self).sendIfNotDisabled() else {
            return []
        }

        return syntaxMap.tokens.compactMap { token in
            guard let kind = SyntaxKind(rawValue: token.type), !syntaxKindsToSkip.contains(kind) else {
                return nil
            }

            let offset = Int64(token.offset)
            let request = Request.cursorInfo(file: path, offset: offset, arguments: compilerArguments)
            guard var cursorInfo = try? request.sendIfNotDisabled() else {
                return nil
            }

            if let acl = File.aclAtOffset(offset, substructureElement: editorOpen) {
                cursorInfo["key.accessibility"] = acl
            }
            cursorInfo["swiftlint.offset"] = offset
            return cursorInfo
        }
    }

    static func declaredUSRs(allCursorInfo: [[String: SourceKitRepresentable]], includePublicAndOpen: Bool)
        -> [(usr: String, nameOffset: Int)] {
        return allCursorInfo.compactMap { cursorInfo in
            return declaredUSRAndOffset(cursorInfo: cursorInfo, includePublicAndOpen: includePublicAndOpen)
        }
    }

    static func referencedUSRs(allCursorInfo: [[String: SourceKitRepresentable]]) -> [String] {
        return allCursorInfo.compactMap(referencedUSR)
    }

    static func testCaseUSRs(allCursorInfo: [[String: SourceKitRepresentable]]) -> Set<String> {
        return Set(allCursorInfo.compactMap(testCaseUSR))
    }

    private static func declaredUSRAndOffset(cursorInfo: [String: SourceKitRepresentable], includePublicAndOpen: Bool)
        -> (usr: String, nameOffset: Int)? {
        if let offset = cursorInfo["swiftlint.offset"] as? Int64,
            let usr = cursorInfo["key.usr"] as? String,
            let kind = (cursorInfo["key.kind"] as? String).flatMap(SwiftDeclarationKind.init(rawValue:)),
            !declarationKindsToSkip.contains(kind),
            let acl = (cursorInfo["key.accessibility"] as? String).flatMap(AccessControlLevel.init(rawValue:)),
            includePublicAndOpen || [.internal, .private, .fileprivate].contains(acl) {
            // Skip declarations marked as @IBOutlet, @IBAction or @objc
            // since those might not be referenced in code, but only dynamically (e.g. Interface Builder)
            if let annotatedDecl = cursorInfo["key.annotated_decl"] as? String,
                ["@IBOutlet", "@IBAction", "@objc", "@IBInspectable"].contains(where: annotatedDecl.contains) {
                return nil
            }

            // Classes marked as @UIApplicationMain are used by the operating system as the entry point into the app.
            if let annotatedDecl = cursorInfo["key.annotated_decl"] as? String,
                annotatedDecl.contains("@UIApplicationMain") {
                return nil
            }

            // Skip declarations that override another. This works for both subclass overrides &
            // protocol extension overrides.
            if cursorInfo["key.overrides"] != nil {
                return nil
            }

            // Sometimes default protocol implementations don't have `key.overrides` set but they do have
            // `key.related_decls`.
            if cursorInfo["key.related_decls"] != nil {
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

    private static func testCaseUSR(cursorInfo: [String: SourceKitRepresentable]) -> String? {
        if let kind = (cursorInfo["key.kind"] as? String).flatMap(SwiftDeclarationKind.init(rawValue:)),
            kind == .class,
            let annotatedDecl = cursorInfo["key.annotated_decl"] as? String,
            annotatedDecl.contains("<Type usr=\"c:objc(cs)XCTestCase\">XCTestCase</Type>"),
            let usr = cursorInfo["key.usr"] as? String {
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

private extension Dictionary where Value == SourceKitRepresentable, Key == String {

    var name: String? {
        return self["key.name"] as? String
    }

}


// Skip initializers, deinit, enum cases and subscripts since we can't reliably detect if they're used.
private let declarationKindsToSkip: Set<SwiftDeclarationKind> = [
    .functionConstructor,
    .functionDestructor,
    .enumelement,
    .functionSubscript
]

/// Skip syntax kinds that won't respond to cursor info requests.
private let syntaxKindsToSkip: Set<SyntaxKind> = [
    .attributeBuiltin,
    .attributeID,
    .comment,
    .commentMark,
    .commentURL,
    .buildconfigID,
    .buildconfigKeyword,
    .docComment,
    .docCommentField,
    .keyword,
    .number,
    .string,
    .stringInterpolationAnchor
]
