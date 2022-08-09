import SourceKittenFramework

public struct RedundantSetAccessControlRule: ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "redundant_set_access_control",
        name: "Redundant Set Access Control Rule",
        description: "Property setter access level shouldn't be explicit if " +
                     "it's the same as the variable access level.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("private(set) public var foo: Int"),
            Example("public let foo: Int"),
            Example("public var foo: Int"),
            Example("var foo: Int"),
            Example("""
            private final class A {
              private(set) var value: Int
            }
            """)
        ],
        triggeringExamples: [
            Example("↓private(set) private var foo: Int"),
            Example("↓fileprivate(set) fileprivate var foo: Int"),
            Example("↓internal(set) internal var foo: Int"),
            Example("↓public(set) public var foo: Int"),
            Example("""
            open class Foo {
              ↓open(set) open var bar: Int
            }
            """),
            Example("""
            class A {
              ↓internal(set) var value: Int
            }
            """),
            Example("""
            fileprivate class A {
              ↓fileprivate(set) var value: Int
            }
            """)
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        return file.structureDictionary.traverseWithParentDepthFirst { parent, subDict in
            guard let kind = subDict.declarationKind else { return nil }
            return validate(file: file, kind: kind, dictionary: subDict, parentDictionary: parent)
        }
    }

    private func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
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

        let acl = dictionary.accessibility
        let resolvedAccessibility: AccessControlLevel? = explicitACL?.acl ?? {
            let parentACL = parentDictionary?.accessibility

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
        if dictionary.accessibility == .private,
            explicitACL == nil,
            dictionary.setterAccessibility.flatMap(AccessControlLevel.init(identifier:)) == .private {
                return []
        }

        return [
            StyleViolation(ruleDescription: Self.description,
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
