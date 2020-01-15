import SourceKittenFramework

private extension SwiftLintFile {
    func missingDocOffsets(in dictionary: SourceKittenDictionary,
                           acls: [AccessControlLevel]) -> [(ByteCount, AccessControlLevel)] {
        if dictionary.enclosedSwiftAttributes.contains(.override) ||
            !dictionary.inheritedTypes.isEmpty {
            return []
        }
        let substructureOffsets = dictionary.substructure.flatMap {
            missingDocOffsets(in: $0, acls: acls)
        }
        let extensionKinds: Set<SwiftDeclarationKind> = [.extension, .extensionEnum, .extensionClass,
                                                         .extensionStruct, .extensionProtocol]
        guard let kind = dictionary.declarationKind,
            !extensionKinds.contains(kind),
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

public struct MissingDocsRule: OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
    public init() {
        configuration = MissingDocsRuleConfiguration(
            parameters: [RuleParameter<AccessControlLevel>(severity: .warning, value: .open),
                         RuleParameter<AccessControlLevel>(severity: .warning, value: .public)])
    }

    public typealias ConfigurationType = MissingDocsRuleConfiguration
    public var configuration: MissingDocsRuleConfiguration

    public static let description = RuleDescription(
        identifier: "missing_docs",
        name: "Missing Docs",
        description: "Declarations should be documented.",
        kind: .lint,
        minSwiftVersion: .fourDotOne,
        nonTriggeringExamples: [
            // locally-defined superclass member is documented, but subclass member is not
            Example("""
            /// docs
            public class A {
            /// docs
            public func b() {}
            }
            /// docs
            public class B: A { override public func b() {} }
            """),
            // externally-defined superclass member is documented, but subclass member is not
            Example("""
            import Foundation
            /// docs
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
            """)
        ],
        triggeringExamples: [
            // public, undocumented
            Example("public func a() {}\n"),
            // public, undocumented
            Example("// regular comment\npublic func a() {}\n"),
            // public, undocumented
            Example("/* regular comment */\npublic func a() {}\n"),
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
            """)
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let acls = configuration.parameters.map { $0.value }
        let dict = file.structureDictionary
        return file.missingDocOffsets(in: dict, acls: acls).map { offset, acl in
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.parameters.first { $0.value == acl }?.severity ?? .warning,
                           location: Location(file: file, byteOffset: offset),
                           reason: "\(acl.description) declarations should be documented.")
        }
    }
}
