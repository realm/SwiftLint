import SourceKittenFramework

private extension File {
    func missingDocOffsets(in dictionary: [String: SourceKitRepresentable],
                           acls: [AccessControlLevel]) -> [(Int, AccessControlLevel)] {
        if dictionary.enclosedSwiftAttributes.contains(.override) ||
            !dictionary.inheritedTypes.isEmpty {
            return []
        }
        let substructureOffsets = dictionary.substructure.flatMap {
            missingDocOffsets(in: $0, acls: acls)
        }
        guard (dictionary.kind).flatMap(SwiftDeclarationKind.init) != nil,
            let offset = dictionary.offset,
            let accessibility = dictionary.accessibility,
            let acl = AccessControlLevel(identifier: accessibility),
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
            "/// docs\npublic class A {\n/// docs\npublic func b() {}\n}\n" +
            "/// docs\npublic class B: A { override public func b() {} }\n",
            // externally-defined superclass member is documented, but subclass member is not
            "import Foundation\n/// docs\npublic class B: NSObject {\n" +
            "// no docs\noverride public var description: String { fatalError() } }\n"
        ],
        triggeringExamples: [
            // public, undocumented
            "public func a() {}\n",
            // public, undocumented
            "// regular comment\npublic func a() {}\n",
            // public, undocumented
            "/* regular comment */\npublic func a() {}\n",
            // protocol member and inherited member are both undocumented
            "/// docs\npublic protocol A {\n// no docs\nvar b: Int { get } }\n" +
            "/// docs\npublic struct C: A {\n\npublic let b: Int\n}"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        let acls = configuration.parameters.map { $0.value }
        return file.missingDocOffsets(in: file.structure.dictionary,
                                      acls: acls).map { (offset: Int, acl: AccessControlLevel) in
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.parameters.first { $0.value == acl }?.severity ?? .warning,
                           location: Location(file: file, byteOffset: offset),
                           reason: "\(acl.description) declarations should be documented.")
        }
    }
}
