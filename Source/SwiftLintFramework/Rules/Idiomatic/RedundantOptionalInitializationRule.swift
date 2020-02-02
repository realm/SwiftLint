import Foundation
import SourceKittenFramework

public struct RedundantOptionalInitializationRule: SubstitutionCorrectableASTRule, ConfigurationProviderRule,
                                                   AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "redundant_optional_initialization",
        name: "Redundant Optional Initialization",
        description: "Initializing an optional variable with nil is redundant.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("var myVar: Int?\n"),
            Example("let myVar: Int? = nil\n"),
            Example("var myVar: Int? = 0\n"),
            Example("func foo(bar: Int? = 0) { }\n"),
            Example("var myVar: Optional<Int>\n"),
            Example("let myVar: Optional<Int> = nil\n"),
            Example("var myVar: Optional<Int> = 0\n"),
            // properties with body should be ignored
            Example("""
            var foo: Int? {
              if bar != nil { }
              return 0
            }
            """),
            // properties with a closure call
            Example("""
            var foo: Int? = {
              if bar != nil { }
              return 0
            }()
            """),
            // lazy variables need to be initialized
            Example("lazy var test: Int? = nil"),
            // local variables
            Example("""
            func funcName() {
              var myVar: String?
            }
            """),
            Example("""
            func funcName() {
              let myVar: String? = nil
            }
            """)
        ],
        triggeringExamples: triggeringExamples,
        corrections: corrections
    )

    private static let triggeringExamples: [Example] = {
        let commonExamples = [
            Example("var myVar: Int?↓ = nil\n"),
            Example("var myVar: Optional<Int>↓ = nil\n"),
            Example("var myVar: Int?↓=nil\n"),
            Example("var myVar: Optional<Int>↓=nil\n)")
        ]

        guard SwiftVersion.current >= .fourDotOne else {
            return commonExamples
        }

        return commonExamples + [
            Example("""
            func funcName() {
                var myVar: String?↓ = nil
            }
            """)
        ]
    }()

    private static let corrections: [Example: Example] = {
        var corrections = [
            Example("var myVar: Int?↓ = nil\n"): Example("var myVar: Int?\n"),
            Example("var myVar: Optional<Int>↓ = nil\n"): Example("var myVar: Optional<Int>\n"),
            Example("var myVar: Int?↓=nil\n"): Example("var myVar: Int?\n"),
            Example("var myVar: Optional<Int>↓=nil\n"): Example("var myVar: Optional<Int>\n"),
            Example("class C {\n#if true\nvar myVar: Int?↓ = nil\n#endif\n}"):
                Example("class C {\n#if true\nvar myVar: Int?\n#endif\n}")
        ]

        guard SwiftVersion.current >= .fourDotOne else {
            return corrections
        }

        corrections[Example("""
        func foo() {
            var myVar: String?↓ = nil
        }
        """)] = Example("""
        func foo() {
            var myVar: String?
        }
        """)
        return corrections
    }()

    private let pattern = "\\s*=\\s*nil\\b"

    public func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        return violationRanges(in: file, kind: kind, dictionary: dictionary).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    public func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String)? {
        return (violationRange, "")
    }

    public func violationRanges(in file: SwiftLintFile, kind: SwiftDeclarationKind,
                                dictionary: SourceKittenDictionary) -> [NSRange] {
        guard SwiftDeclarationKind.variableKinds.contains(kind),
            let type = dictionary.typeName,
            typeIsOptional(type),
            !dictionary.enclosedSwiftAttributes.contains(.lazy),
            dictionary.isMutableVariable(file: file),
            let range = range(for: dictionary, file: file),
            let match = file.match(pattern: pattern, with: [.keyword], range: range).first,
            match.location == range.location + range.length - match.length else {
                return []
        }

        return [match]
    }

    private func range(for dictionary: SourceKittenDictionary, file: SwiftLintFile) -> NSRange? {
        guard let offset = dictionary.offset,
            let length = dictionary.length else {
                return nil
        }

        let contents = file.stringView
        if let bodyOffset = dictionary.bodyOffset {
            return contents.byteRangeToNSRange(ByteRange(location: offset, length: bodyOffset - offset))
        } else {
            return contents.byteRangeToNSRange(ByteRange(location: offset, length: length))
        }
    }

    private func typeIsOptional(_ type: String) -> Bool {
        return type.hasSuffix("?") || type.hasPrefix("Optional<")
    }
}

extension SourceKittenDictionary {
    fileprivate func isMutableVariable(file: SwiftLintFile) -> Bool {
        return setterAccessibility != nil || (isLocal && isVariable(file: file))
    }

    private var isLocal: Bool {
        return accessibility == nil && setterAccessibility == nil
    }

    private func isVariable(file: SwiftLintFile) -> Bool {
        guard let byteRange = byteRange,
            case let contents = file.stringView,
            let range = contents.byteRangeToNSRange(byteRange),
            !file.match(pattern: "\\Avar\\b", with: [.keyword], range: range).isEmpty else {
                return false
        }

        return true
    }
}
