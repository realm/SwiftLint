import SourceKittenFramework
import SwiftSyntax

private extension SwiftLintFile {
    func missingDocOffsets(in dictionary: SourceKittenDictionary,
                           acls: [AccessControlLevel],
                           excludesExtensions: Bool,
                           excludesInheritedTypes: Bool,
                           excludesTrivialInit: Bool) -> [(ByteCount, AccessControlLevel)] {
        if dictionary.enclosedSwiftAttributes.contains(.override) ||
            (dictionary.inheritedTypes.isNotEmpty && excludesInheritedTypes) {
            return []
        }
        let substructureOffsets = dictionary.substructure.flatMap {
            missingDocOffsets(
                in: $0,
                acls: acls,
                excludesExtensions: excludesExtensions,
                excludesInheritedTypes: excludesInheritedTypes,
                excludesTrivialInit: excludesTrivialInit
            )
        }

        let isTrivialInit = dictionary.declarationKind == .functionMethodInstance &&
                            dictionary.name == "init()" &&
                            dictionary.enclosedVarParameters.isEmpty
        if isTrivialInit && excludesTrivialInit {
            return substructureOffsets
        }

        guard let kind = dictionary.declarationKind,
            !SwiftDeclarationKind.extensionKinds.contains(kind) || !excludesExtensions,
            case let isDeinit = kind == .functionMethodInstance && dictionary.name == "deinit",
            !isDeinit,
            let offset = dictionary.offset,
            let acl = dictionary.accessibility,
            acls.contains(acl) else {
                return substructureOffsets
        }
        if dictionary.docLength != nil {
            return substructureOffsets
        }
        return substructureOffsets + [(offset, acl)]
    }
}

struct MissingDocsRule: OptInRule {
    init() {
        configuration = MissingDocsConfiguration()
    }

    typealias ConfigurationType = MissingDocsConfiguration

    var configuration: MissingDocsConfiguration

    static let description = RuleDescription(
        identifier: "missing_docs",
        name: "Missing Docs",
        description: "Declarations should be documented.",
        kind: .lint,
        nonTriggeringExamples: [
            // locally-defined superclass member is documented, but subclass member is not
            Example("""
            /// docs
            public class A {
            /// docs
            public func b() {}
            }
            // no docs
            public class B: A { override public func b() {} }
            """),
            // externally-defined superclass member is documented, but subclass member is not
            Example("""
            import Foundation
            // no docs
            public class B: NSObject {
            // no docs
            override public var description: String { fatalError() } }
            """),
            Example("""
            /// docs
            public class A {
                deinit {}
            }
            """),
            Example("""
            public extension A {}
            """),
            Example("""
            /// docs
            public class A {
                public init() {}
            }
            """, configuration: ["excludes_trivial_init": true])
        ],
        triggeringExamples: [
            // public, undocumented
            Example("public func a() {}"),
            // public, undocumented
            Example("// regular comment\npublic func a() {}"),
            // public, undocumented
            Example("/* regular comment */\npublic func a() {}"),
            // protocol member and inherited member are both undocumented
            Example("""
            /// docs
            public protocol A {
            // no docs
            var b: Int { get } }
            /// docs
            public struct C: A {

            public let b: Int
            }
            """),
            Example("""
            /// docs
            public class A {
                public init(argument: String) {}
            }
            """, configuration: ["excludes_trivial_init": true])
        ]
    )

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        let acls = configuration.parameters.map { $0.value }
        let dict = file.structureDictionary
        let isImplictlyActorDecleation: Bool = ClassDeclaratopmVisitor(viewMode: .sourceAccurate)
            .walk(tree: file.syntaxTree, handler: \.isActorImplicitlyHerited)

        if isImplictlyActorDecleation && configuration.excludesInheritedTypes {
            return []
        }
        return file.missingDocOffsets(
            in: dict,
            acls: acls,
            excludesExtensions: configuration.excludesExtensions,
            excludesInheritedTypes: configuration.excludesInheritedTypes,
            excludesTrivialInit: configuration.excludesTrivialInit
        ).map { offset, acl in
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.parameters.first { $0.value == acl }?.severity ?? .warning,
                           location: Location(file: file, byteOffset: offset),
                           reason: "\(acl.description) declarations should be documented")
        }
    }
}

private class ClassDeclaratopmVisitor: SyntaxVisitor {
    private(set) var isActorImplicitlyHerited = false

    override func visitPost(_ node: ActorDeclSyntax) {
        isActorImplicitlyHerited = true
    }
}
