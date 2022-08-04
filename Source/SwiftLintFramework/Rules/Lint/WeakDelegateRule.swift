import Foundation
import SourceKittenFramework

public struct WeakDelegateRule: OptInRule, ASTRule, SubstitutionCorrectableASTRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "weak_delegate",
        name: "Weak Delegate",
        description: "Delegates should be weak to avoid reference cycles.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("class Foo {\n  weak var delegate: SomeProtocol?\n}\n"),
            Example("class Foo {\n  weak var someDelegate: SomeDelegateProtocol?\n}\n"),
            Example("class Foo {\n  weak var delegateScroll: ScrollDelegate?\n}\n"),
            // We only consider properties to be a delegate if it has "delegate" in its name
            Example("class Foo {\n  var scrollHandler: ScrollDelegate?\n}\n"),
            // Only trigger on instance variables, not local variables
            Example("func foo() {\n  var delegate: SomeDelegate\n}\n"),
            // Only trigger when variable has the suffix "-delegate" to avoid false positives
            Example("class Foo {\n  var delegateNotified: Bool?\n}\n"),
            // There's no way to declare a property weak in a protocol
            Example("protocol P {\n var delegate: AnyObject? { get set }\n}\n"),
            Example("class Foo {\n protocol P {\n var delegate: AnyObject? { get set }\n}\n}\n"),
            Example("class Foo {\n var computedDelegate: ComputedDelegate {\n return bar() \n} \n}"),
            Example("struct Foo {\n @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate \n}")
        ],
        triggeringExamples: [
            Example("class Foo {\n  ↓var delegate: SomeProtocol?\n}\n"),
            Example("class Foo {\n  ↓var scrollDelegate: ScrollDelegate?\n}\n")
        ],
        corrections: [
            Example("class Foo {\n  ↓var delegate: SomeProtocol?\n}\n"):
                Example("class Foo {\n  weak var delegate: SomeProtocol?\n}\n"),
            Example("class Foo {\n  ↓var scrollDelegate: ScrollDelegate?\n}\n"):
                Example("class Foo {\n  weak var scrollDelegate: ScrollDelegate?\n}\n")
        ]
    )

    public func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        return violationRanges(in: file, kind: kind, dictionary: dictionary).map {
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    public func violationRanges(in file: SwiftLintFile, kind: SwiftDeclarationKind,
                                dictionary: SourceKittenDictionary) -> [NSRange] {
        guard kind == .varInstance else {
            return []
        }

        // Check if name contains "delegate"
        guard let name = dictionary.name,
            name.lowercased().hasSuffix("delegate") else {
                return []
        }

        // Check if non-weak
        let isWeak = dictionary.enclosedSwiftAttributes.contains(.weak)
        guard !isWeak else { return [] }

        // if the declaration is inside a protocol
        if let offset = dictionary.offset,
            protocolDeclarations(forByteOffset: offset, structureDictionary: file.structureDictionary).isNotEmpty {
            return []
        }

        // Check if non-computed
        let isComputed = (dictionary.bodyLength ?? 0) > 0
        guard !isComputed else { return [] }

        // Check for UIApplicationDelegateAdaptor
        for attribute in dictionary.swiftAttributes {
            if
                let offset = attribute.offset,
                let length = attribute.length,
                let value = file.stringView.substringWithByteRange(ByteRange(location: offset, length: length)),
                value.hasPrefix("@UIApplicationDelegateAdaptor") {
                return []
            }
        }

        guard let offset = dictionary.offset,
            let range = file.stringView.byteRangeToNSRange(ByteRange(location: offset, length: 3))
        else {
            return []
        }

        return [range]
    }

    public func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String)? {
        return (violationRange, "weak var")
    }

    private func protocolDeclarations(forByteOffset byteOffset: ByteCount,
                                      structureDictionary: SourceKittenDictionary) -> [SourceKittenDictionary] {
        return structureDictionary.traverseBreadthFirst { dictionary in
            guard dictionary.declarationKind == .protocol,
                let byteRange = dictionary.byteRange,
                byteRange.contains(byteOffset)
            else {
                return nil
            }
            return [dictionary]
        }
    }
}
