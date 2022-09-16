import SourceKittenFramework

public struct TypeACLOrderRule: ConfigurationProviderRule, OptInRule {
    private typealias Declaration = (acl: AccessControlLevel, offset: ByteCount)
    private typealias TypeStructure = [TypeContent: [Declaration]]

    public static let description = RuleDescription(
        identifier: "type_acl_order",
        name: "Type ACL Order",
        description: "Specifies the access control level order within a type.",
        kind: .style,
        nonTriggeringExamples: TypeACLOrderRuleExamples.nonTriggeringExamples,
        triggeringExamples: TypeACLOrderRuleExamples.triggeringExamples
    )

    public var configuration = TypeACLOrderConfiguration()

    public init() {}

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        typeStructures(in: file.structureDictionary).flatMap { typeStructure in
            validateTypeStructure(typeStructure, with: configuration.order, in: file)
        }
    }

    private func typeStructures(in structure: SourceKittenDictionary) -> [TypeStructure] {
        structure.substructure.flatMap { substructure in
            [typeStructure(from: substructure)] + typeStructures(in: substructure)
        }
    }

    private func typeStructure(from structure: SourceKittenDictionary) -> TypeStructure {
        var typeStructure = TypeStructure()

        structure.substructure.forEach { substructure in
            guard let type = TypeContent(structure: substructure),
                  let acl = substructure.accessibility,
                  let offset = substructure.offset else { return }

            let declaration = Declaration(acl, offset)
            typeStructure[type, default: []].append(declaration)
        }

        return typeStructure
    }

    private func validateTypeStructure(_ typeStructure: TypeStructure, with order: [AccessControlLevel],
                                       in file: SwiftLintFile) -> [StyleViolation] {
        typeStructure.flatMap { type, declarations -> [StyleViolation] in
            var lastValidACLIndex = order.startIndex

            return declarations.compactMap { declaration in
                guard let aclIndex = order.firstIndex(of: declaration.acl) else { return nil }

                if aclIndex < lastValidACLIndex {
                    let invalidACL = "'\(declaration.acl.description) \(type)'".prependingArticle(capitalized: true)
                    let validACL = "'\(order[lastValidACLIndex].description) \(type)'".prependingArticle()

                    return StyleViolation(
                        ruleDescription: Self.description,
                        severity: configuration.severityConfiguration.severity,
                        location: Location(file: file, byteOffset: declaration.offset),
                        reason: "\(invalidACL) should not be declared after \(validACL)."
                    )
                } else {
                    lastValidACLIndex = aclIndex
                    return nil
                }
            }
        }.sorted { $0.location < $1.location }
    }
}
