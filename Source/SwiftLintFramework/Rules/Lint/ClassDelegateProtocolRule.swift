import Foundation
import SourceKittenFramework

public struct ClassDelegateProtocolRule: ASTRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "class_delegate_protocol",
        name: "Class Delegate Protocol",
        description: "Delegate protocols should be class-only so they can be weakly referenced.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("protocol FooDelegate: class {}\n"),
            Example("protocol FooDelegate: class, BarDelegate {}\n"),
            Example("protocol Foo {}\n"),
            Example("class FooDelegate {}\n"),
            Example("@objc protocol FooDelegate {}\n"),
            Example("@objc(MyFooDelegate)\n protocol FooDelegate {}\n"),
            Example("protocol FooDelegate: BarDelegate {}\n"),
            Example("protocol FooDelegate: AnyObject {}\n"),
            Example("protocol FooDelegate: NSObjectProtocol {}\n")
        ],
        triggeringExamples: [
            Example("↓protocol FooDelegate {}\n"),
            Example("↓protocol FooDelegate: Bar {}\n")
        ]
    )

    private let referenceTypeProtocols: Set = ["AnyObject", "NSObjectProtocol", "class"]

    public func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard kind == .protocol else {
            return []
        }

        // Check if name contains "Delegate"
        guard let name = dictionary.name, isDelegateProtocol(name) else {
            return []
        }

        // Check if @objc
        let objcAttributes: Set<SwiftDeclarationAttributeKind> = [.objc, .objcName]
        let isObjc = !objcAttributes.isDisjoint(with: dictionary.enclosedSwiftAttributes)
        guard !isObjc else {
            return []
        }

        // Check if inherits from another Delegate protocol
        guard !dictionary.inheritedTypes.contains(where: isDelegateProtocol) else {
            return []
        }

        // Check if inherits from a known reference type protocol
        guard !dictionary.inheritedTypes.contains(where: isReferenceTypeProtocol) else {
            return []
        }

        // Check if : class
        guard let offset = dictionary.offset,
            let nameOffset = dictionary.nameOffset,
            let nameLength = dictionary.nameLength,
            let bodyOffset = dictionary.bodyOffset,
            case let contents = file.stringView,
            case let start = nameOffset + nameLength,
            case let byteRange = ByteRange(location: start, length: bodyOffset - start),
            let range = contents.byteRangeToNSRange(byteRange),
            !isClassProtocol(file: file, range: range)
        else {
            return []
        }

        return [
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: offset))
        ]
    }

    private func isClassProtocol(file: SwiftLintFile, range: NSRange) -> Bool {
        return !file.match(pattern: "\\bclass\\b", with: [.keyword], range: range).isEmpty
    }

    private func isDelegateProtocol(_ name: String) -> Bool {
        return name.hasSuffix("Delegate")
    }

    private func isReferenceTypeProtocol(_ name: String) -> Bool {
        return referenceTypeProtocols.contains(name)
    }
}
