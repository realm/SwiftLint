import Foundation
import SourceKittenFramework

struct UnusedDeclarationRule: ConfigurationProviderRule, AnalyzerRule, CollectingRule {
    struct FileUSRs: Hashable {
        var referenced: Set<String>
        var declared: Set<DeclaredUSR>

        fileprivate static var empty: FileUSRs { Self(referenced: [], declared: []) }
    }

    struct DeclaredUSR: Hashable {
        let usr: String
        let nameOffset: ByteCount
    }

    typealias FileInfo = FileUSRs

    var configuration = UnusedDeclarationConfiguration(
        severity: .error,
        includePublicAndOpen: false,
        relatedUSRsToSkip: ["s:7SwiftUI15PreviewProviderP"]
    )

    init() {}

    static let description = RuleDescription(
        identifier: "unused_declaration",
        name: "Unused Declaration",
        description: "Declarations should be referenced at least once within all files linted.",
        kind: .lint,
        nonTriggeringExamples: UnusedDeclarationRuleExamples.nonTriggeringExamples,
        triggeringExamples: UnusedDeclarationRuleExamples.triggeringExamples,
        requiresFileOnDisk: true
    )

    func collectInfo(for file: SwiftLintFile, compilerArguments: [String]) -> UnusedDeclarationRule.FileUSRs {
        guard compilerArguments.isNotEmpty else {
            queuedPrintError("""
                Attempted to lint file at path '\(file.path ?? "...")' with the \
                \(Self.description.identifier) rule without any compiler arguments.
                """)
            return .empty
        }

        guard let index = file.index(compilerArguments: compilerArguments), index.value.isNotEmpty else {
            queuedPrintError("""
                Could not index file at path '\(file.path ?? "...")' with the \
                \(Self.description.identifier) rule.
                """)
            return .empty
        }

        guard let editorOpen = (try? Request.editorOpen(file: file.file).sendIfNotDisabled())
                .map(SourceKittenDictionary.init) else {
            queuedPrintError("""
                Could not open file at path '\(file.path ?? "...")' with the \
                \(Self.description.identifier) rule.
                """)
            return .empty
        }

        return FileUSRs(
            referenced: file.referencedUSRs(index: index),
            declared: file.declaredUSRs(index: index,
                                        editorOpen: editorOpen,
                                        compilerArguments: compilerArguments,
                                        configuration: configuration)
        )
    }

    func validate(file: SwiftLintFile, collectedInfo: [SwiftLintFile: UnusedDeclarationRule.FileUSRs],
                  compilerArguments: [String]) -> [StyleViolation] {
        let allReferencedUSRs = collectedInfo.values.reduce(into: Set()) { $0.formUnion($1.referenced) }
        return violationOffsets(declaredUSRs: collectedInfo[file]?.declared ?? [],
                                allReferencedUSRs: allReferencedUSRs)
            .map {
                StyleViolation(ruleDescription: Self.description,
                               severity: configuration.severityConfiguration.severity,
                               location: Location(file: file, byteOffset: $0))
            }
    }

    private func violationOffsets(declaredUSRs: Set<DeclaredUSR>, allReferencedUSRs: Set<String>) -> [ByteCount] {
        // Unused declarations are:
        // 1. all declarations
        // 2. minus all references
        return declaredUSRs
            .filter { !allReferencedUSRs.contains($0.usr) }
            .map { $0.nameOffset }
            .sorted()
    }
}

// MARK: - File Extensions

private extension SwiftLintFile {
    func index(compilerArguments: [String]) -> SourceKittenDictionary? {
        return path
            .flatMap { path in
                try? Request.index(file: path, arguments: compilerArguments)
                            .send()
            }
            .map(SourceKittenDictionary.init)
    }

    func referencedUSRs(index: SourceKittenDictionary) -> Set<String> {
        return Set(index.traverseEntitiesDepthFirst { entity -> String? in
            if let usr = entity.usr,
                let kind = entity.kind,
                kind.starts(with: "source.lang.swift.ref") {
                return usr
            }

            return nil
        })
    }

    func declaredUSRs(index: SourceKittenDictionary, editorOpen: SourceKittenDictionary,
                      compilerArguments: [String], configuration: UnusedDeclarationConfiguration)
    -> Set<UnusedDeclarationRule.DeclaredUSR> {
        return Set(index.traverseEntitiesDepthFirst { indexEntity in
            self.declaredUSR(indexEntity: indexEntity, editorOpen: editorOpen, compilerArguments: compilerArguments,
                             configuration: configuration)
        })
    }

    func declaredUSR(indexEntity: SourceKittenDictionary, editorOpen: SourceKittenDictionary,
                     compilerArguments: [String], configuration: UnusedDeclarationConfiguration)
    -> UnusedDeclarationRule.DeclaredUSR? {
        guard let stringKind = indexEntity.kind,
              stringKind.starts(with: "source.lang.swift.decl."),
              !stringKind.contains(".accessor."),
              let usr = indexEntity.usr,
              let line = indexEntity.line,
              let column = indexEntity.column,
              let kind = indexEntity.declarationKind,
              !declarationKindsToSkip.contains(kind)
        else {
            return nil
        }

        if shouldIgnoreEntity(indexEntity, relatedUSRsToSkip: configuration.relatedUSRsToSkip) {
            return nil
        }

        guard let nameOffset = stringView.byteOffset(forLine: line, bytePosition: column) else {
            return nil
        }

        if !configuration.includePublicAndOpen, [.public, .open].contains(editorOpen.aclAtOffset(nameOffset)) {
            return nil
        }

        // Skip CodingKeys as they are used for Codable generation
        if kind == .enum,
            indexEntity.name == "CodingKeys",
            case let allRelatedUSRs = indexEntity.traverseEntitiesDepthFirst(traverseBlock: { $0.usr }),
            allRelatedUSRs.contains("s:s9CodingKeyP") {
            return nil
        }

        // Skip `static var allTests` members since those are used for Linux test discovery.
        if kind == .varStatic, indexEntity.name == "allTests" {
            let allTestCandidates = indexEntity.traverseEntitiesDepthFirst { subEntity -> Bool in
                subEntity.value["key.is_test_candidate"] as? Bool == true
            }

            if allTestCandidates.contains(true) {
                return nil
            }
        }

        let cursorInfo = self.cursorInfo(at: nameOffset, compilerArguments: compilerArguments)

        if cursorInfo?.annotatedDeclaration?.contains("@objc ") == true {
            return nil
        }

        // This works for both subclass overrides & protocol extension overrides.
        if cursorInfo?.value["key.overrides"] != nil {
            return nil
        }

        // Sometimes default protocol implementations don't have `key.overrides` set but they do have
        // `key.related_decls`. The apparent exception is that related declarations also includes declarations
        // with "related names", which appears to be similarly named declarations (i.e. overloads) that are
        // programmatically unrelated to the current cursor-info declaration. Those similarly named declarations
        // aren't in `key.related` so confirm that that one is also populated.
        if cursorInfo?.value["key.related_decls"] != nil && indexEntity.value["key.related"] != nil {
            return nil
        }

        return .init(usr: usr, nameOffset: nameOffset)
    }

    func cursorInfo(at byteOffset: ByteCount, compilerArguments: [String]) -> SourceKittenDictionary? {
        let request = Request.cursorInfo(file: path!, offset: byteOffset, arguments: compilerArguments)
        return (try? request.sendIfNotDisabled()).map(SourceKittenDictionary.init)
    }

    private func shouldIgnoreEntity(_ indexEntity: SourceKittenDictionary, relatedUSRsToSkip: Set<String>) -> Bool {
        if indexEntity.shouldSkipIndexEntityToWorkAroundSR11985() ||
            indexEntity.shouldSkipRelated(relatedUSRsToSkip: relatedUSRsToSkip) ||
            indexEntity.enclosedSwiftAttributes.contains(where: declarationAttributesToSkip.contains) ||
            indexEntity.isImplicit ||
            indexEntity.value["key.is_test_candidate"] as? Bool == true ||
            indexEntity.shouldSkipResultBuilder() {
            return true
        }

        if !Set(indexEntity.enclosedSwiftAttributes).isDisjoint(with: [.ibinspectable, .iboutlet]) {
            if let getter = indexEntity.entities.first(where: { $0.declarationKind == .functionAccessorGetter }),
               !getter.isImplicit {
                return true
            }

            if let setter = indexEntity.entities.first(where: { $0.declarationKind == .functionAccessorSetter }),
               !setter.isImplicit {
                return true
            }

            if !Set(indexEntity.entities.compactMap(\.declarationKind))
                .isDisjoint(with: [.functionAccessorWillset, .functionAccessorDidset]) {
                return true
            }
        }

        return false
    }
}

private extension SourceKittenDictionary {
    var usr: String? {
        return value["key.usr"] as? String
    }

    var annotatedDeclaration: String? {
        return value["key.annotated_decl"] as? String
    }

    var isImplicit: Bool {
        return value["key.is_implicit"] as? Bool == true
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

    func shouldSkipRelated(relatedUSRsToSkip: Set<String>) -> Bool {
        return (value["key.related"] as? [[String: SourceKitRepresentable]])?
            .compactMap { SourceKittenDictionary($0).usr }
            .contains(where: relatedUSRsToSkip.contains) == true
    }

    func shouldSkipIndexEntityToWorkAroundSR11985() -> Bool {
        guard enclosedSwiftAttributes.contains(.objcName), let name = self.name else {
            return false
        }

        // Not a comprehensive list. Add as needed.
        let functionsToSkipForSR11985 = [
            "navigationBar(_:didPop:)",
            "scrollViewDidEndDecelerating(_:)",
            "scrollViewDidEndDragging(_:willDecelerate:)",
            "scrollViewDidScroll(_:)",
            "scrollViewDidScrollToTop(_:)",
            "scrollViewWillBeginDragging(_:)",
            "scrollViewWillEndDragging(_:withVelocity:targetContentOffset:)",
            "tableView(_:canEditRowAt:)",
            "tableView(_:commit:forRowAt:)",
            "tableView(_:editingStyleForRowAt:)",
            "tableView(_:willDisplayHeaderView:forSection:)",
            "tableView(_:willSelectRowAt:)"
        ]

        return functionsToSkipForSR11985.contains(name)
    }

    func shouldSkipResultBuilder() -> Bool {
        guard let name = name, declarationKind == .functionMethodStatic else {
            return false
        }

        // https://github.com/apple/swift-evolution/blob/main/proposals/0289-result-builders.md#result-building-methods
        let resultBuilderStaticMethods = [
            "buildBlock(_:)",
            "buildExpression(_:)",
            "buildOptional(_:)",
            "buildEither(first:)",
            "buildEither(second:)",
            "buildArray(_:)",
            "buildLimitedAvailability(_:)",
            "buildFinalResult(_:)",
            // https://github.com/apple/swift-evolution/blob/main/proposals/0348-buildpartialblock.md
            "buildPartialBlock(first:)",
            "buildPartialBlock(accumulated:next:)"
        ]

        return resultBuilderStaticMethods.contains(name)
    }
}

// Skip initializers, deinit, enum cases and subscripts since we can't reliably detect if they're used.
private let declarationKindsToSkip: Set<SwiftDeclarationKind> = [
    .enumelement,
    .extensionProtocol,
    .extension,
    .extensionEnum,
    .extensionClass,
    .extensionStruct,
    .functionConstructor,
    .functionDestructor,
    .functionSubscript,
    .genericTypeParam
]

private let declarationAttributesToSkip: Set<SwiftDeclarationAttributeKind> = [
    .ibaction,
    .main,
    .nsApplicationMain,
    .override,
    .uiApplicationMain
]
