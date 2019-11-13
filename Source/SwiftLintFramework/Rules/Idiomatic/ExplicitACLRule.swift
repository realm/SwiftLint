import Foundation
import SourceKittenFramework

private typealias SourceKittenElement = SourceKittenDictionary

public struct ExplicitACLRule: OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "explicit_acl",
        name: "Explicit ACL",
        description: "All declarations should specify Access Control Level keywords explicitly.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            "internal enum A {}\n",
            "public final class B {}\n",
            "private struct C {}\n",
            "internal enum A {\n internal enum B {}\n}",
            "internal final class Foo {}",
            """
            internal
            class Foo {
              private let bar = 5
            }
            """,
            "internal func a() { let a =  }\n",
            "private func a() { func innerFunction() { } }",
            "private enum Foo { enum Bar { } }",
            "private struct C { let d = 5 }",
            """
            internal protocol A {
              func b()
            }
            """,
            """
            internal protocol A {
              var b: Int
            }
            """,
            "internal class A { deinit {} }",
            "extension A: Equatable {}",
            "extension A {}"
        ],
        triggeringExamples: [
            "enum A {}\n",
            "final class B {}\n",
            "internal struct C { let d = 5 }\n",
            "public struct C { let d = 5 }\n",
            "func a() {}\n",
            "internal let a = 0\nfunc b() {}\n"
        ]
    )

    private func findAllExplicitInternalTokens(in file: SwiftLintFile) -> [NSRange] {
        let contents = file.linesContainer
        return file.match(pattern: "internal", with: [.attributeBuiltin]).compactMap {
            contents.NSRangeToByteRange(start: $0.location, length: $0.length)
        }
    }

    private func offsetOfElements(from elements: [SourceKittenElement], in file: SwiftLintFile,
                                  thatAreNotInRanges ranges: [NSRange]) -> [Int] {
        let extensionKinds: Set<SwiftDeclarationKind> = [.extension, .extensionClass, .extensionEnum,
                                                         .extensionProtocol, .extensionStruct]

        return elements.compactMap { element in
            guard let typeOffset = element.offset else {
                return nil
            }

            guard let kind = element.declarationKind,
                !extensionKinds.contains(kind) else {
                    return nil
            }

            // find the last "internal" token before the type
            guard let previousInternalByteRange = lastInternalByteRange(before: typeOffset, in: ranges) else {
                return typeOffset
            }

            // the "internal" token correspond to the type if there're only
            // attributeBuiltin (`final` for example) tokens between them
            let length = typeOffset - previousInternalByteRange.location
            let range = NSRange(location: previousInternalByteRange.location, length: length)
            let internalDoesntBelongToType = Set(file.syntaxMap.kinds(inByteRange: range)) != [.attributeBuiltin]

            return internalDoesntBelongToType ? typeOffset : nil
        }
    }

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let implicitAndExplicitInternalElements = internalTypeElements(in: file.structureDictionary )

        guard !implicitAndExplicitInternalElements.isEmpty else {
            return []
        }

        let explicitInternalRanges = findAllExplicitInternalTokens(in: file)

        let violations = offsetOfElements(from: implicitAndExplicitInternalElements, in: file,
                                          thatAreNotInRanges: explicitInternalRanges)

        return violations.map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: $0))
        }
    }

    private func lastInternalByteRange(before typeOffset: Int, in ranges: [NSRange]) -> NSRange? {
        let firstPartition = ranges.prefix(while: { typeOffset > $0.location })
        return firstPartition.last
    }

    private func internalTypeElements(in element: SourceKittenElement) -> [SourceKittenElement] {
        return element.substructure.flatMap { element -> [SourceKittenElement] in
            guard let elementKind = element.declarationKind else {
                return []
            }

            let isDeinit = elementKind == .functionMethodInstance && element.name == "deinit"
            guard !isDeinit else {
                return []
            }

            let isPrivate = element.accessibility?.isPrivate ?? false
            let internalTypeElementsInSubstructure = elementKind.childsAreExemptFromACL || isPrivate ? [] :
                internalTypeElements(in: element)

            if element.accessibility == .internal {
                return internalTypeElementsInSubstructure + [element]
            }

            return internalTypeElementsInSubstructure
        }
    }
}

private extension SwiftDeclarationKind {
    var childsAreExemptFromACL: Bool {
        switch self {
        case .associatedtype, .enumcase, .enumelement, .functionAccessorAddress,
             .functionAccessorDidset, .functionAccessorGetter, .functionAccessorMutableaddress,
             .functionAccessorSetter, .functionAccessorWillset, .genericTypeParam, .module,
             .precedenceGroup, .varLocal, .varParameter, .varClass,
             .varGlobal, .varInstance, .varStatic, .typealias, .functionAccessorModify, .functionAccessorRead,
             .functionConstructor, .functionDestructor, .functionFree, .functionMethodClass,
             .functionMethodInstance, .functionMethodStatic, .functionOperator, .functionOperatorInfix,
             .functionOperatorPostfix, .functionOperatorPrefix, .functionSubscript, .protocol, .opaqueType:
            return true
        case .class, .enum, .extension, .extensionClass, .extensionEnum,
             .extensionProtocol, .extensionStruct, .struct:
            return false
        }
    }
}
