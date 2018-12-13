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
            """
            class Foo {
              var myVar: Int? = 0
            }
            """,
            """
            class Foo {
              let myVar: Int? = 0
            }
            """,
            """
            class Foo {
              static var myVar: Int? = 0
            }
            """,
            """
            class Foo {
              class var myVar: Int? = 0
            }
            """
        ],
        triggeringExamples: [
            """
            class Foo {
              ↓var myVar = 0
            }
            """,
            """
            class Foo {
              ↓let mylet = 0
            }
            """,
            """
            class Foo {
              ↓static var myStaticVar = 0
            }
            """,
            """
            class Foo {
              ↓class var myClassVar = 0
            }
            """,
            """
            class Foo {
              ↓let myVar = Int(0)
            }
            """,
            """
            class Foo {
              ↓let myVar = Set<Int>(0)
            }
            """
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
