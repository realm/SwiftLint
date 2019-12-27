import Foundation
import SourceKittenFramework

public struct WeakDelegateRule: ASTRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "weak_delegate",
        name: "Weak Delegate",
        description: "Delegates should be weak to avoid reference cycles.",
        kind: .lint,
        nonTriggeringExamples: [
            "class Foo {\n  weak var delegate: SomeProtocol?\n}\n",
            "class Foo {\n  weak var someDelegate: SomeDelegateProtocol?\n}\n",
            "class Foo {\n  weak var delegateScroll: ScrollDelegate?\n}\n",
            // We only consider properties to be a delegate if it has "delegate" in its name
            "class Foo {\n  var scrollHandler: ScrollDelegate?\n}\n",
            // Only trigger on instance variables, not local variables
            "func foo() {\n  var delegate: SomeDelegate\n}\n",
            // Only trigger when variable has the suffix "-delegate" to avoid false positives
            "class Foo {\n  var delegateNotified: Bool?\n}\n",
            // There's no way to declare a property weak in a protocol
            "protocol P {\n var delegate: AnyObject? { get set }\n}\n",
            "class Foo {\n protocol P {\n var delegate: AnyObject? { get set }\n}\n}\n",
            "class Foo {\n var computedDelegate: ComputedDelegate {\n return bar() \n} \n}"
        ],
        triggeringExamples: [
            "class Foo {\n  ↓var delegate: SomeProtocol?\n}\n",
            "class Foo {\n  ↓var scrollDelegate: ScrollDelegate?\n}\n"
        ]
    )

    public func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
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
            !protocolDeclarations(forByteOffset: offset, structureDictionary: file.structureDictionary).isEmpty {
            return []
        }

        // Check if non-computed
        let isComputed = (dictionary.bodyLength ?? 0) > 0
        guard !isComputed else { return [] }

        // Violation found!
        let location: Location
        if let offset = dictionary.offset {
            location = Location(file: file, byteOffset: offset)
        } else {
            location = Location(file: file.path)
        }

        return [
            StyleViolation(
                ruleDescription: type(of: self).description,
                severity: configuration.severity,
                location: location
            )
        ]
    }

    private func protocolDeclarations(forByteOffset byteOffset: Int,
                                      structureDictionary: SourceKittenDictionary) -> [SourceKittenDictionary] {
        return structureDictionary.traverseBreadthFirst { dictionary in
            guard dictionary.declarationKind == .protocol,
                let byteRange = dictionary.byteRange,
                NSLocationInRange(byteOffset, byteRange) else {
                    return nil
            }
            return [dictionary]
        }
    }
}
