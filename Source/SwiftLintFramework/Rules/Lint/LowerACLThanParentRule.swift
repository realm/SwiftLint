import SourceKittenFramework

public struct LowerACLThanParentRule: OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "lower_acl_than_parent",
        name: "Lower ACL than parent",
        description: "Ensure definitions have a lower access control level than their enclosing parent",
        kind: .lint,
        nonTriggeringExamples: [
            Example("public struct Foo { public func bar() {} }"),
            Example("internal struct Foo { func bar() {} }"),
            Example("struct Foo { func bar() {} }"),
            Example("open class Foo { public func bar() {} }"),
            Example("open class Foo { open func bar() {} }"),
            Example("fileprivate struct Foo { private func bar() {} }"),
            Example("private struct Foo { private func bar(id: String) }"),
            Example("extension Foo { public func bar() {} }"),
            Example("private struct Foo { fileprivate func bar() {} }"),
            Example("private func foo(id: String) {}"),
            Example("private class Foo { func bar() {} }")
        ],
        triggeringExamples: [
            Example("struct Foo { public ↓func bar() {} }"),
            Example("enum Foo { public ↓func bar() {} }"),
            Example("public class Foo { open ↓func bar() }"),
            Example("class Foo { public private(set) ↓var bar: String? }"),
            Example("private class Foo { internal ↓func bar() {} }")
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        return validateACL(isHigherThan: .open, in: file.structureDictionary).map {
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: $0))
        }
    }

    private func validateACL(isHigherThan parentAccessibility: AccessControlLevel,
                             in substructure: SourceKittenDictionary) -> [ByteCount] {
        return substructure.substructure.flatMap { element -> [ByteCount] in
            guard let elementKind = element.declarationKind,
                elementKind.isRelevantDeclaration else {
                return []
            }

            var violationOffset: ByteCount?
            let accessibility = element.accessibility ?? .internal
            // Swift 5 infers members of private types with no explicit ACL attribute to be `internal`.
            let isInferredACL = accessibility == .internal && !element.enclosedSwiftAttributes.contains(.internal)
            if !isInferredACL, accessibility.priority > parentAccessibility.priority {
                violationOffset = element.offset
            }

            return [violationOffset].compactMap { $0 } + self.validateACL(isHigherThan: accessibility, in: element)
        }
    }
}

private extension SwiftDeclarationKind {
    var isRelevantDeclaration: Bool {
        switch self {
        case .associatedtype, .enumcase, .enumelement, .extension, .extensionClass, .extensionEnum,
             .extensionProtocol, .extensionStruct, .functionAccessorAddress, .functionAccessorDidset,
             .functionAccessorRead, .functionAccessorModify, .functionAccessorGetter,
             .functionAccessorMutableaddress, .functionAccessorSetter, .functionAccessorWillset,
             .functionDestructor, .genericTypeParam, .module, .precedenceGroup, .varLocal, .varParameter, .opaqueType:
            return false
        case .class, .enum, .functionConstructor, .functionFree, .functionMethodClass, .functionMethodInstance,
             .functionMethodStatic, .functionOperator, .functionOperatorInfix, .functionOperatorPostfix,
             .functionOperatorPrefix, .functionSubscript, .protocol, .struct, .typealias, .varClass, .varGlobal,
             .varInstance, .varStatic:
            return true
        }
    }
}

private extension AccessControlLevel {
    var priority: Int {
        switch self {
        case .private: return 1
        case .fileprivate: return 1
        case .internal: return 2
        case .public: return 3
        case .open: return 4
        }
    }
}
