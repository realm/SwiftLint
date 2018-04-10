//
//  LowerACLThanParentRule.swift
//  SwiftLint
//
//  Created by Keith Smiley on 4/3/18.
//  Copyright © 2018 Realm. All rights reserved.
//

import Foundation
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
            "public struct Foo { public func bar() {} }",
            "internal struct Foo { func bar() {} }",
            "struct Foo { func bar() {} }",
            "open class Foo { public func bar() {} }",
            "open class Foo { open func bar() {} }",
            "fileprivate struct Foo { private func bar() {} }",
            "private struct Foo { private func bar(id: String) }",
            "private func foo(id: String) {}"
        ],
        triggeringExamples: [
            "struct Foo { public func bar() {} }",
            "extension Foo { public func bar() {} }",
            "enum Foo { public func bar() {} }",
            "public class Foo { open func bar() }",
            "private struct Foo { fileprivate func bar() {} }",
            "class Foo { public private(set) var bar: String? }"
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
            guard let elementKind = element.kind.flatMap(SwiftDeclarationKind.init(rawValue:)),
                elementKind.isRelevantDeclaration else {
                return []
            }

            var violationOffset: Int?
            let accessibility = element.accessibility.flatMap(AccessControlLevel.init(identifier:))
                ?? .`internal`
            if accessibility > parentAccessibility {
                violationOffset = element.offset
            }

            return [violationOffset].compactMap { $0 } + self.validateACL(isHigherThan: accessibility, in: element)
        }
    }
}

private extension SwiftDeclarationKind {
    var isRelevantDeclaration: Bool {
        switch self {
        case .`associatedtype`, .enumcase, .enumelement, .functionAccessorAddress,
             .functionAccessorDidset, .functionAccessorGetter, .functionAccessorMutableaddress,
             .functionAccessorSetter, .functionAccessorWillset, .functionDestructor, .genericTypeParam, .module,
             .precedenceGroup, .varLocal, .varParameter:
            return false
        case .`class`, .`enum`, .`extension`, .`extensionClass`, .`extensionEnum`,
             .extensionProtocol, .extensionStruct, .functionConstructor,
             .functionFree, .functionMethodClass, .functionMethodInstance, .functionMethodStatic,
             .functionOperator, .functionOperatorInfix, .functionOperatorPostfix, .functionOperatorPrefix,
             .functionSubscript, .`protocol`, .`struct`, .`typealias`, .varClass,
             .varGlobal, .varInstance, .varStatic:
            return true
        }
    }
}
