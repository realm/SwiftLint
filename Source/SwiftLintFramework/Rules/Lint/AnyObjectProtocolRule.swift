import Foundation
import SourceKittenFramework

public struct AnyObjectProtocolRule: SubstitutionCorrectableASTRule, OptInRule,
                                     ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "anyobject_protocol",
        name: "AnyObject Protocol",
        description: "Prefer using `AnyObject` over `class` for class-only protocols.",
        kind: .lint,
        minSwiftVersion: .fourDotOne,
        nonTriggeringExamples: [
            "protocol SomeProtocol {}\n",
            "protocol SomeClassOnlyProtocol: AnyObject {}\n",
            "protocol SomeClassOnlyProtocol: AnyObject, SomeInheritedProtocol {}\n",
            "@objc protocol SomeClassOnlyProtocol: AnyObject, SomeInheritedProtocol {}\n"
        ],
        triggeringExamples: [
            "protocol SomeClassOnlyProtocol: ↓class {}\n",
            "protocol SomeClassOnlyProtocol: ↓class, SomeInheritedProtocol {}\n",
            "@objc protocol SomeClassOnlyProtocol: ↓class, SomeInheritedProtocol {}\n"
        ],
        corrections: [
            "protocol SomeClassOnlyProtocol: ↓class {}\n":
                "protocol SomeClassOnlyProtocol: AnyObject {}\n",
            "protocol SomeClassOnlyProtocol: ↓class, SomeInheritedProtocol {}\n":
                "protocol SomeClassOnlyProtocol: AnyObject, SomeInheritedProtocol {}\n",
            "protocol SomeClassOnlyProtocol: SomeInheritedProtocol, ↓class {}\n":
                "protocol SomeClassOnlyProtocol: SomeInheritedProtocol, AnyObject {}\n",
            "@objc protocol SomeClassOnlyProtocol: ↓class, SomeInheritedProtocol {}\n":
                "@objc protocol SomeClassOnlyProtocol: AnyObject, SomeInheritedProtocol {}\n"
        ]
    )

    // MARK: - ASTRule

    public func validate(file: SwiftLintFile,
                         kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        return violationRanges(in: file, kind: kind, dictionary: dictionary).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    // MARK: - SubstitutionCorrectableASTRule

    public func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String) {
        return (violationRange, "AnyObject")
    }

    public func violationRanges(in file: SwiftLintFile,
                                kind: SwiftDeclarationKind,
                                dictionary: SourceKittenDictionary) -> [NSRange] {
        guard kind == .protocol else { return [] }

        return dictionary.elements.compactMap { subDict -> NSRange? in
            guard
                let offset = subDict.offset,
                let length = subDict.length,
                let content = file.linesContainer.substringWithByteRange(start: offset, length: length),
                content == "class"
                else {
                    return nil
            }

            return file.linesContainer.byteRangeToNSRange(start: offset, length: length)
        }
    }
}
