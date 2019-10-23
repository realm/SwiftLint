import SourceKittenFramework

public struct RedundantSetAccessControlRule: ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "redundant_set_access_control",
        name: "Redundant Set Access Control Rule",
        description: "Property setter access level shouldn't be explicit if " +
                     "it's the same as the variable access level.",
        kind: .idiomatic,
        minSwiftVersion: .fourDotOne,
        nonTriggeringExamples: [
            "private(set) public var foo: Int",
            "public let foo: Int",
            "public var foo: Int",
            "var foo: Int",
            """
            private final class A {
              private(set) var value: Int
            }
            """
        ],
        triggeringExamples: [
            "↓private(set) private var foo: Int",
            "↓fileprivate(set) fileprivate var foo: Int",
            "↓internal(set) internal var foo: Int",
            "↓public(set) public var foo: Int",
            """
            open class Foo {
              ↓open(set) open var bar: Int
            }
            """,
            """
            class A {
              ↓internal(set) var value: Int
            }
            """,
            """
            fileprivate class A {
              ↓fileprivate(set) var value: Int
            }
            """
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        return validate(file: file, dictionary: SourceKittenDictionary(value: file.structure.dictionary), parentDictionary: nil)
    }

    private func validate(file: File, dictionary: SourceKittenDictionary,
                          parentDictionary: SourceKittenDictionary?) -> [StyleViolation] {
        return dictionary.substructure.flatMap { subDict -> [StyleViolation] in
            var violations = validate(file: file, dictionary: subDict, parentDictionary: dictionary)

            if let kindString = subDict.kind,
                let kind = SwiftDeclarationKind(rawValue: kindString) {
                violations += validate(file: file, kind: kind, dictionary: subDict, parentDictionary: dictionary)
            }

            return violations
        }
    }

    private func validate(file: File, kind: SwiftDeclarationKind,
                          dictionary: SourceKittenDictionary,
                          parentDictionary: SourceKittenDictionary?) -> [StyleViolation] {
        let aclAttributes: Set<SwiftDeclarationAttributeKind> = [.private, .fileprivate, .internal, .public, .open]
        let explicitACL = dictionary.swiftAttributes.compactMap { dict -> SwiftDeclarationAttributeKind? in
            guard let attribute = dict.attribute.flatMap(SwiftDeclarationAttributeKind.init),
                aclAttributes.contains(attribute) else {
                    return nil
            }

            return attribute
        }.first

        let acl = dictionary.accessibility.flatMap(AccessControlLevel.init(identifier:))
        let resolvedAccessibility: AccessControlLevel? = explicitACL?.acl ?? {
            let parentACL = parentDictionary?.accessibility.flatMap(AccessControlLevel.init(identifier:))

            if acl == .internal, let parentACL = parentACL, parentACL == .fileprivate {
                return .fileprivate
            } else {
                return acl
            }
        }()

        guard SwiftDeclarationKind.variableKinds.contains(kind),
            resolvedAccessibility?.rawValue == dictionary.setterAccessibility else {
                return []
        }

        let explicitSetACL = dictionary.swiftAttributes.first { dict in
            return dict.attribute?.hasPrefix("source.decl.attribute.setter_access") ?? false
        }

        guard let offset = explicitSetACL?.offset else {
            return []
        }

        // if it's an inferred `private`, it means the variable is actually inside a fileprivate structure
        if dictionary.accessibility.flatMap(AccessControlLevel.init(identifier:)) == .private,
            explicitACL == nil,
            dictionary.setterAccessibility.flatMap(AccessControlLevel.init(identifier:)) == .private {
                return []
        }

        return [
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: offset))
        ]
    }
}

private extension SwiftDeclarationAttributeKind {
    var acl: AccessControlLevel? {
        switch self {
        case .private:
            return .private
        case .fileprivate:
            return .fileprivate
        case .internal:
            return .internal
        case .public:
            return .public
        case .open:
            return .open
        default:
            return nil
        }
    }
}
