import SourceKittenFramework

private extension SwiftLintFile {
    enum SignatureDeclaration {
        case returnType(String)
        case parameter(String)

        var description: String {
            switch self {
            case .returnType(let name):
                return "Return type `\(name)` should be documented."
            case .parameter(let name):
                return "Parameter `\(name)` should be documented."
            }
        }
    }

    func incompleteDocumentationOffsets(in dictionary: SourceKittenDictionary,
                                        acls: [AccessControlLevel]) -> [(ByteCount, SignatureDeclaration)] {
        if dictionary.enclosedSwiftAttributes.contains(.override) ||
            dictionary.inheritedTypes.isNotEmpty {
            return []
        }
        let substructureOffsets = dictionary.substructure.flatMap {
            incompleteDocumentationOffsets(in: $0, acls: acls)
        }
        guard
            let offset = dictionary.offset,
            let acl = dictionary.accessibility,
            acls.contains(acl),
            let docOffset = dictionary.docOffset,
            let docLength = dictionary.docLength else {
                return substructureOffsets
        }
        let syntaxToken = SyntaxToken(type: SyntaxKind.docComment.rawValue, offset: docOffset, length: docLength)
        guard let documentation = contents(for: SwiftLintSyntaxToken(value: syntaxToken)) else {
            return substructureOffsets
        }

        var undocumentedOffsets = [(ByteCount, SignatureDeclaration)]()
        for sub in dictionary.substructure {
            if sub.declarationKind == SwiftDeclarationKind.varParameter,
               let subName = sub.name,
               let subOffset = sub.offset {
                if documentation.contains("- Parameters:") {
                    if !documentation.contains("- \(subName):") {
                        undocumentedOffsets.append((subOffset, .parameter(subName)))
                    }
                } else {
                    if !documentation.contains("- Parameter \(subName):") {
                        undocumentedOffsets.append((subOffset, .parameter(subName)))
                    }
                }
            }
        }

        let declarationKinds: Set<SwiftDeclarationKind> = [.functionMethodClass,
                                                           .functionMethodStatic,
                                                           .functionMethodInstance,
                                                           .functionFree]
        if let typeName = dictionary.typeName,
           !documentation.contains("- Returns:"),
           let declarationKind = dictionary.declarationKind,
           declarationKinds.contains(declarationKind) {
            undocumentedOffsets.append((offset, .returnType(typeName)))
        }

        return substructureOffsets + undocumentedOffsets
    }

    func missingDocOffsets(in dictionary: SourceKittenDictionary,
                           acls: [AccessControlLevel]) -> [(ByteCount, AccessControlLevel)] {
        if dictionary.enclosedSwiftAttributes.contains(.override) ||
            dictionary.inheritedTypes.isNotEmpty {
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
                         RuleParameter<AccessControlLevel>(severity: .warning, value: .public)],
            mindIncompleteDocs: true)
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
            """),
            // public, parameter documented
            Example("""
            /// docs
            /// - Parameter a: docs
            public func a(a: Bool) {}
            """),
            Example("""
            /// docs
            /// - Parameters:
            ///   - a: docs
            public func a(a: Bool) {}
            """),
            // public, return type documented
            Example("""
            /// docs
            /// - Returns: docs
            public func a() -> Bool {
                return true
            }
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
            """),
            // public, parameter not documented
            Example("""
            /// docs
            public func a(a: Bool) {}
            """),
            // public, wrong parameter documented
            Example("""
            /// docs
            /// - Parameter b: docs
            public func a(a: Bool) {}
            """),
            Example("""
            /// docs
            /// - Parameters:
            ///   - b: docs
            public func a(a: Bool) {}
            """),
            // public, return type not documented
            Example("""
            /// docs
            public func a() -> Bool {
                return true
            }
            """)
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let acls = configuration.parameters.map { $0.value }
        let dict = file.structureDictionary

        let violations = file.missingDocOffsets(in: dict, acls: acls).map { offset, acl in
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.parameters.first { $0.value == acl }?.severity ?? .warning,
                           location: Location(file: file, byteOffset: offset),
                           reason: "\(acl.description) declarations should be documented.")
        }

        guard configuration.mindIncompleteDocs == true else {
            return violations
        }

        return violations + file.incompleteDocumentationOffsets(in: dict, acls: acls).map { offset, declaration in
            StyleViolation(ruleDescription: Self.description,
                           severity: .warning,
                           location: Location(file: file, byteOffset: offset),
                           reason: declaration.description)
        }
    }
}
