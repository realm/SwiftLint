import SourceKittenFramework

public struct LowerACLThanParentRule: OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "lower_acl_than_parent",
        name: "Lower ACL than parent",
        description: "Ensure definitions have a lower access control level than their enclosing parent",
        kind: .lint,
        nonTriggeringExamples: [
            "public struct Foo { public func bar() {} }",
            "internal struct Foo { func bar() {} }",
            "struct Foo { func bar() {} }",
            "open class Foo { public func bar() {} }",
            "open class Foo { open func bar() {} }",
            "fileprivate struct Foo { private func bar() {} }",
            "private struct Foo { private func bar(id: String) }",
            "extension Foo { public func bar() {} }",
            "private struct Foo { fileprivate func bar() {} }",
            "private func foo(id: String) {}",
            "private class Foo { func bar() {} }"
        ],
        triggeringExamples: [
            "struct Foo { public ↓func bar() {} }",
            "enum Foo { public ↓func bar() {} }",
            "public class Foo { open ↓func bar() }",
            "class Foo { public private(set) ↓var bar: String? }",
            "private class Foo { internal ↓func bar() {} }"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        return validateACL(isHigherThan: .open, in: file.structure.dictionary).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: $0))
        }
    }

    private func validateACL(isHigherThan parentAccessibility: AccessControlLevel,
                             in substructure: [String: SourceKitRepresentable]) -> [Int] {
        return substructure.substructure.flatMap { element -> [Int] in
            guard let elementKind = element.kind.flatMap(SwiftDeclarationKind.init),
                elementKind.isRelevantDeclaration else {
                return []
            }

            var violationOffset: Int?
            let accessibility = element.accessibility.flatMap(AccessControlLevel.init(identifier:)) ?? .internal
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
             .functionAccessorGetter, .functionAccessorMutableaddress, .functionAccessorSetter,
             .functionAccessorWillset, .functionDestructor, .genericTypeParam, .module, .precedenceGroup, .varLocal,
             .varParameter:
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
