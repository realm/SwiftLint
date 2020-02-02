import Foundation
import SourceKittenFramework

public struct UnusedDeclarationRule: AutomaticTestableRule, ConfigurationProviderRule, AnalyzerRule, CollectingRule {
    public struct FileUSRs {
        var referenced: Set<String>
        var declared: [(usr: String, nameOffset: ByteCount)]
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
            Example("""
            let kConstant = 0
            _ = kConstant
            """),
            Example("""
            enum Change<T> {
              case insert(T)
              case delete(T)
            }

            extension Sequence {
              func deletes<T>() -> [T] where Element == Change<T> {
                return compactMap { operation in
                  if case .delete(let value) = operation {
                    return value
                  } else {
                    return nil
                  }
                }
              }
            }

            let changes = [Change.insert(0), .delete(0)]
            changes.deletes()
            """),
            Example("""
            struct Item {}
            struct ResponseModel: Codable {
                let items: [Item]

                enum CodingKeys: String, CodingKey {
                    case items = "ResponseItems"
                }
            }

            _ = ResponseModel(items: [Item()]).items
            """),
            Example("""
            class ResponseModel {
                @objc func foo() {
                }
            }
            _ = ResponseModel()
            """)
        ],
        triggeringExamples: [
            Example("""
            let ↓kConstant = 0
            """),
            Example("""
            struct Item {}
            struct ↓ResponseModel: Codable {
                let ↓items: [Item]

                enum ↓CodingKeys: String {
                    case items = "ResponseItems"
                }
            }
            """),
            Example("""
            class ↓ResponseModel {
                func ↓foo() {
                }
            }
            """)
        ],
        requiresFileOnDisk: true
    )

    public func collectInfo(for file: SwiftLintFile, compilerArguments: [String]) -> UnusedDeclarationRule.FileUSRs {
        guard !compilerArguments.isEmpty else {
            queuedPrintError("""
                Attempted to lint file at path '\(file.path ?? "...")' with the \
                \(type(of: self).description.identifier) rule without any compiler arguments.
                """)
            return FileUSRs(referenced: [], declared: [], testCaseUSRs: [])
        }

        let allCursorInfo = file.allCursorInfo(compilerArguments: compilerArguments)
        return FileUSRs(referenced: Set(SwiftLintFile.referencedUSRs(allCursorInfo: allCursorInfo)),
                        declared: SwiftLintFile.declaredUSRs(allCursorInfo: allCursorInfo,
                                                             includePublicAndOpen: configuration.includePublicAndOpen),
                        testCaseUSRs: SwiftLintFile.testCaseUSRs(allCursorInfo: allCursorInfo))
    }

    public func validate(file: SwiftLintFile, collectedInfo: [SwiftLintFile: UnusedDeclarationRule.FileUSRs],
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

    private func violationOffsets(in file: SwiftLintFile, compilerArguments: [String],
                                  declaredUSRs: [(usr: String, nameOffset: ByteCount)],
                                  allReferencedUSRs: Set<String>,
                                  allTestCaseUSRs: Set<String>) -> [ByteCount] {
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

private extension SwiftLintFile {
    func allCursorInfo(compilerArguments: [String]) -> [SourceKittenDictionary] {
        guard let path = path,
            let editorOpen = (try? Request.editorOpen(file: self.file).sendIfNotDisabled())
                .map(SourceKittenDictionary.init) else {
            return []
        }

        return syntaxMap.tokens
            .compactMap { token in
                guard let kind = token.kind, !syntaxKindsToSkip.contains(kind) else {
                    return nil
                }

                let offset = token.offset
                let request = Request.cursorInfo(file: path, offset: offset, arguments: compilerArguments)
                guard var cursorInfo = try? request.sendIfNotDisabled() else {
                    return nil
                }

                if let acl = editorOpen.aclAtOffset(offset) {
                    cursorInfo["key.accessibility"] = acl.rawValue
                }
                cursorInfo["swiftlint.offset"] = Int64(offset.value)
                return cursorInfo
            }
            .map(SourceKittenDictionary.init)
    }

    static func declaredUSRs(allCursorInfo: [SourceKittenDictionary], includePublicAndOpen: Bool)
        -> [(usr: String, nameOffset: ByteCount)] {
        return allCursorInfo.compactMap { cursorInfo in
            return declaredUSRAndOffset(cursorInfo: cursorInfo, includePublicAndOpen: includePublicAndOpen)
        }
    }

    static func referencedUSRs(allCursorInfo: [SourceKittenDictionary]) -> [String] {
        return allCursorInfo.compactMap(referencedUSR)
    }

    static func testCaseUSRs(allCursorInfo: [SourceKittenDictionary]) -> Set<String> {
        return Set(allCursorInfo.compactMap(testCaseUSR))
    }

    private static func declaredUSRAndOffset(cursorInfo: SourceKittenDictionary, includePublicAndOpen: Bool)
        -> (usr: String, nameOffset: ByteCount)? {
        if let offset = cursorInfo.swiftlintOffset,
            let usr = cursorInfo.usr,
            let kind = cursorInfo.declarationKind,
            !declarationKindsToSkip.contains(kind),
            let acl = cursorInfo.accessibility,
            includePublicAndOpen || [.internal, .private, .fileprivate].contains(acl) {
            // Skip declarations marked as @IBOutlet, @IBAction or @objc
            // since those might not be referenced in code, but only dynamically (e.g. Interface Builder)
            if let annotatedDecl = cursorInfo.annotatedDeclaration,
                ["@IBOutlet", "@IBAction", "@objc", "@IBInspectable"].contains(where: annotatedDecl.contains) {
                return nil
            }

            // Classes marked as @UIApplicationMain are used by the operating system as the entry point into the app.
            if let annotatedDecl = cursorInfo.annotatedDeclaration,
                annotatedDecl.contains("@UIApplicationMain") {
                return nil
            }

            // Skip declarations that override another. This works for both subclass overrides &
            // protocol extension overrides.
            if cursorInfo.value["key.overrides"] != nil {
                return nil
            }

            // Sometimes default protocol implementations don't have `key.overrides` set but they do have
            // `key.related_decls`.
            if cursorInfo.value["key.related_decls"] != nil {
                return nil
            }

            // Skip CodingKeys as they are used
            if kind == .enum,
                cursorInfo.name == "CodingKeys",
                let annotatedDecl = cursorInfo.annotatedDeclaration,
                annotatedDecl.contains("usr=\"s:s9CodingKeyP\">CodingKey<") {
                return nil
            }

            return (usr, ByteCount(offset))
        }

        return nil
    }

    private static func referencedUSR(cursorInfo: SourceKittenDictionary) -> String? {
        if let usr = cursorInfo.usr,
            let kind = cursorInfo.kind,
            kind.starts(with: "source.lang.swift.ref") {
            if let synthesizedLocation = usr.range(of: "::SYNTHESIZED::")?.lowerBound {
                return String(usr.prefix(upTo: synthesizedLocation))
            }
            return usr
        }

        return nil
    }

    private static func testCaseUSR(cursorInfo: SourceKittenDictionary) -> String? {
        if let kind = cursorInfo.declarationKind,
            kind == .class,
            let annotatedDecl = cursorInfo.annotatedDeclaration,
            annotatedDecl.contains("<Type usr=\"c:objc(cs)XCTestCase\">XCTestCase</Type>"),
            let usr = cursorInfo.usr {
            return usr
        }

        return nil
    }
}

private extension SourceKittenDictionary {
    var swiftlintOffset: Int64? {
        return value["swiftlint.offset"] as? Int64
    }

    var usr: String? {
        return value["key.usr"] as? String
    }

    var annotatedDeclaration: String? {
        return value["key.annotated_decl"] as? String
    }

    func aclAtOffset(_ offset: ByteCount) -> AccessControlLevel? {
        if let nameOffset = nameOffset,
            nameOffset == offset,
            let acl = accessibility {
            return acl
        }
        for child in substructure {
            if let acl = child.aclAtOffset(offset) {
                return acl
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
