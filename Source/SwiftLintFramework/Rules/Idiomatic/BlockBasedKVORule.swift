import Foundation
import SourceKittenFramework

public struct BlockBasedKVORule: ASTRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "block_based_kvo",
        name: "Block Based KVO",
        description: "Prefer the new block based KVO API with keypaths when using Swift 3.2 or later.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("""
            let observer = foo.observe(\\.value, options: [.new]) { (foo, change) in
               print(change.newValue)
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            class Foo: NSObject {
              override ↓func observeValue(forKeyPath keyPath: String?, of object: Any?,
                                          change: [NSKeyValueChangeKey : Any]?,
                                          context: UnsafeMutableRawPointer?) {}
            }
            """),
            Example("""
            class Foo: NSObject {
              override ↓func observeValue(forKeyPath keyPath: String?, of object: Any?,
                                          change: Dictionary<NSKeyValueChangeKey, Any>?,
                                          context: UnsafeMutableRawPointer?) {}
            }
            """)
        ]
    )

    public func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard kind == .functionMethodInstance,
            dictionary.enclosedSwiftAttributes.contains(.override),
            dictionary.name == "observeValue(forKeyPath:of:change:context:)",
            hasExpectedParamTypes(types: dictionary.enclosedVarParameters.parameterTypes),
            let offset = dictionary.offset else {
                return []
        }

        return [
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: offset))
        ]
    }

    private func hasExpectedParamTypes(types: [String]) -> Bool {
        guard types.count == 4,
            types[0] == "String?",
            types[1] == "Any?",
            types[2] == "[NSKeyValueChangeKey:Any]?" || types[2] == "Dictionary<NSKeyValueChangeKey,Any>?",
            types[3] == "UnsafeMutableRawPointer?" else {
                return false
        }

        return true
    }
}

private extension Array where Element == SourceKittenDictionary {
    var parameterTypes: [String] {
        return compactMap { element in
            guard element.declarationKind == .varParameter else {
                return nil
            }

            return element.typeName?.replacingOccurrences(of: " ", with: "")
        }
    }
}
