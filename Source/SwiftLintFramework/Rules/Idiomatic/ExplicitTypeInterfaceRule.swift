import Foundation
import SourceKittenFramework

public struct ExplicitTypeInterfaceRule: ASTRule, OptInRule, ConfigurationProviderRule {
    public var configuration = ExplicitTypeInterfaceConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "explicit_type_interface",
        name: "Explicit Type Interface",
        description: "Properties should have a type interface",
        kind: .idiomatic,
        nonTriggeringExamples: [
            "class Foo {\n  var myVar: Int? = 0\n}\n",
            "class Foo {\n  let myVar: Int? = 0\n}\n",
            "class Foo {\n  static var myVar: Int? = 0\n}\n",
            "class Foo {\n  class var myVar: Int? = 0\n}\n"
        ],
        triggeringExamples: [
            "class Foo {\n  ↓var myVar = 0\n\n}\n",
            "class Foo {\n  ↓let mylet = 0\n\n}\n",
            "class Foo {\n  ↓static var myStaticVar = 0\n}\n",
            "class Foo {\n  ↓class var myClassVar = 0\n}\n",
            "class Foo {\n  ↓let myVar = Int(0)\n}\n",
            "class Foo {\n  ↓let myVar = Set<Int>(0)\n}\n"
        ]
    )

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {

        guard configuration.allowedKinds.contains(kind),
            !containsType(dictionary: dictionary),
            (!configuration.allowRedundancy || !assigneeIsInitCall(file: file, dictionary: dictionary)),
            let offset = dictionary.offset else {
                return []
        }

        return [
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severityConfiguration.severity,
                           location: Location(file: file, byteOffset: offset))
        ]
    }

    private func containsType(dictionary: [String: SourceKitRepresentable]) -> Bool {
        return dictionary.typeName != nil
    }

    private func assigneeIsInitCall(file: File, dictionary: [String: SourceKitRepresentable]) -> Bool {
        guard
            let nameOffset = dictionary.nameOffset,
            let nameLength = dictionary.nameLength,
            let afterNameRange = file.contents.bridge().byteRangeToNSRange(start: nameOffset + nameLength, length: 0)
        else {
            return false
        }

        let contentAfterName = file.contents.bridge().substring(from: afterNameRange.location)
        let initCallRegex = regex(
            "^\\s*=\\s*(?:try[!?]?\\s+)?\\[?\\p{Lu}[^\\(\\s<]*(?:<[^\\>]*>)?(?::\\s*[^\\(\\n]+)?\\]?\\("
        )

        return initCallRegex.firstMatch(in: contentAfterName, options: [], range: contentAfterName.fullNSRange) != nil
    }
}
