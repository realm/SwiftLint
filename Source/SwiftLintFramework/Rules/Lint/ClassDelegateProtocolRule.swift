import Foundation
import SourceKittenFramework

public struct ClassDelegateProtocolRule: ASTRule, ConfigurationProviderRule {
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
            Example("protocol FooDelegate: NSObjectProtocol {}\n"),
            Example("protocol FooDelegate where Self: BarDelegate {}\n"),
            Example("protocol FooDelegate where Self: AnyObject {}\n"),
            Example("protocol FooDelegate where Self: NSObjectProtocol {}\n")
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

        // Check in direct inheritance and `where` constraints for:
        // reference type protocol, another Delegate protocol, or `class`.
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
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: offset))
        ]
    }

    private func isClassProtocol(file: SwiftLintFile, range: NSRange) -> Bool {
        let characterSet = Set(" {:&,\n")
        return file.stringView.substring(with: range)
            .split(whereSeparator: characterSet.contains)
            // Check if it inherits from a delegate or if its reference bound
            .contains { isDelegateProtocol($0) || isReferenceTypeProtocol($0) }
    }

    private func isDelegateProtocol<S: StringProtocol>(_ name: S) -> Bool {
        return name.hasSuffix("Delegate")
    }

    private func isReferenceTypeProtocol<S: StringProtocol>(_ name: S) -> Bool {
        return referenceTypeProtocols.contains(String(name))
    }
}
