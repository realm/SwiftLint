import Foundation
import SourceKittenFramework

public struct OverexposedDeclarationRule: AutomaticTestableRule, ConfigurationProviderRule, AnalyzerRule,
    CollectingRule {
    public struct Declaration: Hashable {
        let usr: String
        let acl: AccessControlLevel
        let location: Location
    }

    public struct Reference: Hashable {
        let usr: String
        let location: Location
    }

    public struct FileUSRs {
        var referenced: Set<Reference>
        var declared: Set<Declaration>
    }

    public typealias FileInfo = FileUSRs

    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "overexposed_declaration",
        name: "Overexposed Declaration",
        description: "Declarations should be exposed to the lowest accessibility level needed to compile.",
        kind: .lint,
        nonTriggeringExamples: [
            """
            private let kConstant = 0
            _ = kConstant
            """,
            """
            private func foo() {}
            foo()
            """
        ],
        triggeringExamples: [
            """
            let ↓kConstant = 0
            _ = kConstant
            """,
            """
            func ↓foo() {}
            foo()
            """
        ],
        requiresFileOnDisk: true
    )

    public func collectInfo(for file: SwiftLintFile, compilerArguments: [String])
        -> OverexposedDeclarationRule.FileUSRs {
        guard !compilerArguments.isEmpty else {
            queuedPrintError("""
                Attempted to lint file at path '\(file.path ?? "...")' with the \
                \(type(of: self).description.identifier) rule without any compiler arguments.
                """)
            return FileUSRs(referenced: [], declared: [])
        }

        let allCursorInfo = file.allCursorInfo(compilerArguments: compilerArguments)
        return FileUSRs(referenced: Set(file.referencedUSRs(allCursorInfo: allCursorInfo)),
                        declared: Set(file.declaredUSRs(allCursorInfo: allCursorInfo)))
    }

    public func validate(file: SwiftLintFile, collectedInfo: [SwiftLintFile: OverexposedDeclarationRule.FileUSRs],
                         compilerArguments: [String]) -> [StyleViolation] {
        let allDeclarations = collectedInfo.values.reduce(into: Set()) { $0.formUnion($1.declared) }
        let allReferences = collectedInfo.values.reduce(into: Set()) { $0.formUnion($1.referenced) }
        let shouldBePrivateDeclarations = allDeclarations
            .filter { $0.location.file == file.path }
            .filter { $0.acl == .internal }
            .filter { declaration in
                return [declaration.location.file!] ==
                    Set(allReferences.filter({ $0.usr == declaration.usr }).map({ $0.location.file! }))
            }

        return shouldBePrivateDeclarations.map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: $0.location)
        }
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

                let offset = Int64(token.offset)
                let request = Request.cursorInfo(file: path, offset: offset, arguments: compilerArguments)
                guard var cursorInfo = try? request.sendIfNotDisabled() else {
                    return nil
                }

                if let acl = editorOpen.aclAtOffset(offset) {
                    cursorInfo["key.accessibility"] = acl.rawValue
                }
                cursorInfo["swiftlint.offset"] = offset
                return cursorInfo
            }
            .map(SourceKittenDictionary.init)
    }

    func declaredUSRs(allCursorInfo: [SourceKittenDictionary]) -> [OverexposedDeclarationRule.Declaration] {
        return allCursorInfo.compactMap { cursorInfo in
            return declaredUSRPayload(cursorInfo: cursorInfo)
        }
    }

    func referencedUSRs(allCursorInfo: [SourceKittenDictionary]) -> [OverexposedDeclarationRule.Reference] {
        return allCursorInfo.compactMap(referencedUSR)
    }

    private func declaredUSRPayload(cursorInfo: SourceKittenDictionary) -> OverexposedDeclarationRule.Declaration? {
        guard let offset = cursorInfo.swiftlintOffset ?? cursorInfo.offset,
            let usr = cursorInfo.usr,
            let kind = cursorInfo.declarationKind,
            declarationKindsToLint.contains(kind),
            let acl = cursorInfo.accessibility else {
            return nil
        }

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

        // Skip XCTestCase subclasses as they are commonly not private
        if kind == .class,
            let annotatedDecl = cursorInfo.annotatedDeclaration,
            annotatedDecl.contains("usr=\"c:objc(cs)XCTestCase\"") {
            return nil
        }

        let location = Location(file: self, byteOffset: Int(offset))
        return OverexposedDeclarationRule.Declaration(usr: usr, acl: acl, location: location)
    }

    private func referencedUSR(cursorInfo: SourceKittenDictionary) -> OverexposedDeclarationRule.Reference? {
        guard let offset = cursorInfo.swiftlintOffset ?? cursorInfo.offset,
            let usr = cursorInfo.usr,
            let kind = cursorInfo.kind,
            kind.starts(with: "source.lang.swift.ref") else {
            return nil
        }

        let returnUSR: String

        if let synthesizedLocation = usr.range(of: "::SYNTHESIZED::")?.lowerBound {
            returnUSR = String(usr.prefix(upTo: synthesizedLocation))
        } else {
            returnUSR = usr
        }

        let location = Location(file: self, byteOffset: Int(offset))
        return OverexposedDeclarationRule.Reference(usr: returnUSR, location: location)
    }
}

private extension SourceKittenDictionary {
    var swiftlintOffset: Int? {
        return value["swiftlint.offset"] as? Int
    }

    var usr: String? {
        return value["key.usr"] as? String
    }

    var annotatedDeclaration: String? {
        return value["key.annotated_decl"] as? String
    }

    func aclAtOffset(_ offset: Int64) -> AccessControlLevel? {
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

/// Only top-level functions and values can reliably be determined to be overexposed.
private let declarationKindsToLint: Set<SwiftDeclarationKind> = [ // TODO: Expand supported kinds
    .functionFree,
    .varGlobal,
    .struct,
    .enum,
    .class
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
