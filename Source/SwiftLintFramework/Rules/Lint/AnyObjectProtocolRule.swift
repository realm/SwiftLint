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
            Example("protocol SomeProtocol {}\n"),
            Example("protocol SomeClassOnlyProtocol: AnyObject {}\n"),
            Example("protocol SomeClassOnlyProtocol: AnyObject, SomeInheritedProtocol {}\n"),
            Example("@objc protocol SomeClassOnlyProtocol: AnyObject, SomeInheritedProtocol {}\n")
        ],
        triggeringExamples: [
            Example("protocol SomeClassOnlyProtocol: ↓class {}\n"),
            Example("protocol SomeClassOnlyProtocol: ↓class, SomeInheritedProtocol {}\n"),
            Example("@objc protocol SomeClassOnlyProtocol: ↓class, SomeInheritedProtocol {}\n")
        ],
        corrections: [
            Example("protocol SomeClassOnlyProtocol: ↓class {}\n"):
                Example("protocol SomeClassOnlyProtocol: AnyObject {}\n"),
            Example("protocol SomeClassOnlyProtocol: ↓class, SomeInheritedProtocol {}\n"):
                Example("protocol SomeClassOnlyProtocol: AnyObject, SomeInheritedProtocol {}\n"),
            Example("@objc protocol SomeClassOnlyProtocol: ↓class, SomeInheritedProtocol {}\n"):
                Example("@objc protocol SomeClassOnlyProtocol: AnyObject, SomeInheritedProtocol {}\n")
        ]
    )

    // MARK: - ASTRule

    public func validate(file: SwiftLintFile,
                         kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        return violationRanges(in: file, kind: kind, dictionary: dictionary).map {
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    // MARK: - SubstitutionCorrectableASTRule

    public func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String)? {
        return (violationRange, "AnyObject")
    }

    public func violationRanges(in file: SwiftLintFile,
                                kind: SwiftDeclarationKind,
                                dictionary: SourceKittenDictionary) -> [NSRange] {
        guard kind == .protocol else { return [] }

        return dictionary.elements.compactMap { subDict -> NSRange? in
            guard
                let byteRange = subDict.byteRange,
                let content = file.stringView.substringWithByteRange(byteRange),
                content == "class"
            else {
                return nil
            }

            return file.stringView.byteRangeToNSRange(byteRange)
        }
    }
}
