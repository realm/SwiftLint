import Foundation
import SourceKittenFramework

private typealias SourceKittenElement = SourceKittenDictionary

struct ExplicitACLRule: OptInRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "explicit_acl",
        name: "Explicit ACL",
        description: "All declarations should specify Access Control Level keywords explicitly.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("internal enum A {}\n"),
            Example("public final class B {}\n"),
            Example("private struct C {}\n"),
            Example("internal enum A {\n internal enum B {}\n}"),
            Example("internal final class Foo {}"),
            Example("""
            internal
            class Foo {
              private let bar = 5
            }
            """),
            Example("internal func a() { let a =  }\n"),
            Example("private func a() { func innerFunction() { } }"),
            Example("private enum Foo { enum Bar { } }"),
            Example("private struct C { let d = 5 }"),
            Example("""
            internal protocol A {
              func b()
            }
            """),
            Example("""
            internal protocol A {
              var b: Int
            }
            """),
            Example("internal class A { deinit {} }"),
            Example("extension A: Equatable {}"),
            Example("extension A {}"),
            Example("""
            extension Foo {
                internal func bar() {}
            }
            """),
            Example("""
            internal enum Foo {
                case bar
            }
            """),
            Example("""
            extension Foo {
                public var isValid: Bool {
                    let result = true
                    return result
                }
            }
            """),
            Example("""
            extension Foo {
                private var isValid: Bool {
                    get {
                        return true
                    }
                    set(newValue) {
                        print(newValue)
                    }
                }
            }
            """)
        ],
        triggeringExamples: [
            Example("↓enum A {}\n"),
            Example("final ↓class B {}\n"),
            Example("internal struct C { ↓let d = 5 }\n"),
            Example("public struct C { ↓let d = 5 }\n"),
            Example("func a() {}\n"),
            Example("internal let a = 0\n↓func b() {}\n"),
            Example("""
            extension Foo {
                ↓func bar() {}
            }
            """)
        ]
    )

    private func findAllExplicitInternalTokens(in file: SwiftLintFile) -> [ByteRange] {
        let contents = file.stringView
        return file.match(pattern: "internal", with: [.attributeBuiltin]).compactMap {
            contents.NSRangeToByteRange(start: $0.location, length: $0.length)
        }
    }

    private func offsetOfElements(from elements: [SourceKittenElement], in file: SwiftLintFile,
                                  thatAreNotInRanges ranges: [ByteRange]) -> [ByteCount] {
        return elements.compactMap { element in
            guard let typeOffset = element.offset else {
                return nil
            }

            guard let kind = element.declarationKind,
                !SwiftDeclarationKind.extensionKinds.contains(kind) else {
                    return nil
            }

            // find the last "internal" token before the type
            guard let previousInternalByteRange = lastInternalByteRange(before: typeOffset, in: ranges) else {
                return typeOffset
            }

            // the "internal" token correspond to the type if there're only
            // attributeBuiltin (`final` for example) tokens between them
            let length = typeOffset - previousInternalByteRange.location
            let range = ByteRange(location: previousInternalByteRange.location, length: length)
            let internalDoesntBelongToType = Set(file.syntaxMap.kinds(inByteRange: range)) != [.attributeBuiltin]

            return internalDoesntBelongToType ? typeOffset : nil
        }
    }

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        let implicitAndExplicitInternalElements = internalTypeElements(in: file.structureDictionary)

        guard implicitAndExplicitInternalElements.isNotEmpty else {
            return []
        }

        let explicitInternalRanges = findAllExplicitInternalTokens(in: file)

        let violations = offsetOfElements(from: implicitAndExplicitInternalElements, in: file,
                                          thatAreNotInRanges: explicitInternalRanges)

        return violations.map {
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: $0))
        }
    }

    private func lastInternalByteRange(before typeOffset: ByteCount, in ranges: [ByteRange]) -> ByteRange? {
        let firstPartition = ranges.prefix(while: { typeOffset > $0.location })
        return firstPartition.last
    }

    private func internalTypeElements(in parent: SourceKittenElement) -> [SourceKittenElement] {
        return parent.substructure.flatMap { element -> [SourceKittenElement] in
            guard let elementKind = element.declarationKind,
                  elementKind != .varLocal, elementKind != .varParameter else {
                return []
            }

            let isDeinit = elementKind == .functionMethodInstance && element.name == "deinit"
            guard !isDeinit else {
                return []
            }

            let isPrivate = element.accessibility?.isPrivate ?? false
            let internalTypeElementsInSubstructure = elementKind.childsAreExemptFromACL || isPrivate ? [] :
                internalTypeElements(in: element)

            var isInExtension = false
            if let kind = parent.declarationKind {
                isInExtension = SwiftDeclarationKind.extensionKinds.contains(kind)
            }

            if element.accessibility == .internal || (element.accessibility == nil && isInExtension) {
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
