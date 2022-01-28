import Foundation
import SourceKittenFramework

public struct PreferSelfInStaticReferencesRule: SubstitutionCorrectableASTRule, OptInRule, AutomaticTestableRule {
    public static let description = RuleDescription(
        identifier: "prefer_self_in_static_references",
        name: "Prefer Self in Static References",
        description: "Static references should be prefixed by `Self` instead of the class name.",
        kind: .style,
        nonTriggeringExamples: [
            Example("""
                class C {
                    static private(set) var i = 0, j = C.i
                    let h = C.i
                    @GreaterThan(C.j) var k: Int
                }
            """),
            Example("""
                class `Self` {
                    static let i = 0
                    func f() -> Int { Self.i }
                }
            """),
            Example("""
                struct T {
                    static let i = 0
                }
                struct S {
                    static let i = 0
                }
                extension T {
                    static let j = S.i + Self.i
                }
            """),
            Example("""
                struct S {
                    struct T {
                        struct R {
                            static let i = 3
                        }
                    }
                    struct R {
                        static let j = S.T.R.i
                    }
                    static let j = Self.T.R.i + Self.R.j
                    let h = Self.T.R.i + Self.R.j
                }
            """),
            Example("""
                class C {
                    static let s = 2
                    func f(i: Int = C.s) -> Int {
                        func g(@GreaterEqualThan(C.s) j: Int = C.s) -> Int { j }
                        return i + Self.s
                    }
                }
            """),
            Example("""
                struct S {
                    static let i = 1
                    static let j = { Self.i }()
                }
                extension S {
                    static let k = { S.j }()
                }
            """)
        ],
        triggeringExamples: [
            Example("""
                struct C {
                    static let i = 0
                    static let j = ↓C.i
                }
            """),
            Example("""
                struct S {
                    static let i = 0
                    func f() -> Int { ↓S.i }
                }
            """),
            Example("""
                class C {
                    struct S {
                        static let i = 2
                        let h = ↓S.i
                    }
                    static let i = 1
                    let h = C.i
                }
            """),
            Example("""
                struct S {
                    struct T {
                        static let i = 3
                    }
                    struct R {
                        static let j = S.T.i
                    }
                    static let h = ↓S.T.i + ↓S.R.j
                }
            """)
        ],
        corrections: [
            Example("""
                struct S {
                    struct T {
                        static let i = 3
                    }
                    static let h = ↓S.T.i
                }
            """): Example("""
                struct S {
                    struct T {
                        static let i = 3
                    }
                    static let h = Self.T.i
                }
            """),
            Example("""
                class S {
                    static func f() { ↓S.g(↓S.f) }
                    static func g(f: () -> Void) { f() }
                }
            """): Example("""
                class S {
                    static func f() { Self.g(Self.f) }
                    static func g(f: () -> Void) { f() }
                }
            """)
        ]
    )

    private static let nestedKindsToIgnore: Set = [
        SwiftDeclarationKind.class,
        SwiftDeclarationKind.enum,
        SwiftDeclarationKind.struct
    ]

    private static let nestedKindsToIgnoreIfClass: Set = [
        SwiftDeclarationKind.varInstance,
        SwiftDeclarationKind.varStatic,
        SwiftDeclarationKind.varParameter
    ]

    public var configuration = SeverityConfiguration(.warning)
    public var configurationDescription = "N/A"

    public init() {}

    public init(configuration: Any) throws {
        throw ConfigurationError.unknownConfiguration
    }

    public func validate(file: SwiftLintFile,
                         kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        violationRanges(in: file, kind: kind, dictionary: dictionary)
            .compactMap(file.stringView.NSRangeToByteRange)
            .map { byteRange in
                StyleViolation(
                    ruleDescription: Self.description,
                    severity: configuration.severity,
                    location: Location(file: file, byteOffset: byteRange.location)
                )
            }
    }

    public func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String)? {
        (violationRange, "Self.")
    }

    public func violationRanges(in file: SwiftLintFile,
                                kind: SwiftDeclarationKind,
                                dictionary: SourceKittenDictionary) -> [NSRange] {
        guard isComplexDeclaration(kind), let name = dictionary.name, let bodyRange = dictionary.bodyByteRange else {
            return []
        }

        var rangesToIgnore = dictionary.substructure
            .flatMap { getSubstructuresToIgnore(in: $0, containedIn: kind) }
            .compactMap(\.byteRange)
            .unique
            .sorted { $0.location < $1.location }
        rangesToIgnore.append(ByteRange(location: bodyRange.upperBound, length: 0)) // Marks the end of the search

        var location = bodyRange.location
        return rangesToIgnore
            .flatMap { (range: ByteRange) -> [NSRange] in
                if range.location < location {
                    location = max(range.upperBound, location)
                    return []
                }
                let searchRange = ByteRange(location: location, length: range.lowerBound - location)
                location = range.upperBound
                return file.match(
                    pattern: "(?<!\\.)\\b\(name)\\.",
                    with: [.identifier],
                    range: file.stringView.byteRangeToNSRange(searchRange))
            }
    }

    private func isComplexDeclaration(_ kind: SwiftDeclarationKind) -> Bool {
        kind == .class || kind == .struct || kind == .enum
    }

    private func getSubstructuresToIgnore(in structure: SourceKittenDictionary,
                                          containedIn parentKind: SwiftDeclarationKind) -> [SourceKittenDictionary] {
        guard let kind = structure.kind, let declarationKind = SwiftDeclarationKind(rawValue: kind) else {
            return []
        }
        if Self.nestedKindsToIgnore.contains(declarationKind) {
            return [structure]
        }
        if parentKind != .class {
            return []
        }
        var structures = structure.swiftAttributes
        if Self.nestedKindsToIgnoreIfClass.contains(declarationKind) {
            structures.append(structure)
            return structures
        }
        return structures + structure.substructure
            .flatMap { getSubstructuresToIgnore(in: $0, containedIn: parentKind) }
    }
}
