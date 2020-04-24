import Foundation
import SourceKittenFramework

public struct ImplicitlyUnwrappedOptionalRule: ASTRule, ConfigurationProviderRule, OptInRule {
    public var configuration = ImplicitlyUnwrappedOptionalConfiguration(mode: .allExceptIBOutlets,
                                                                        severity: SeverityConfiguration(.warning))

    public init() {}

    public static let description = RuleDescription(
        identifier: "implicitly_unwrapped_optional",
        name: "Implicitly Unwrapped Optional",
        description: "Implicitly unwrapped optionals should be avoided when possible.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("@IBOutlet private var label: UILabel!"),
            Example("@IBOutlet var label: UILabel!"),
            Example("@IBOutlet var label: [UILabel!]"),
            Example("if !boolean {}"),
            Example("let int: Int? = 42"),
            Example("let int: Int? = nil")
        ],
        triggeringExamples: [
            Example("let label: UILabel!"),
            Example("let IBOutlet: UILabel!"),
            Example("let labels: [UILabel!]"),
            Example("var ints: [Int!] = [42, nil, 42]"),
            Example("let label: IBOutlet!"),
            Example("let int: Int! = 42"),
            Example("let int: Int! = nil"),
            Example("var int: Int! = 42"),
            Example("let int: ImplicitlyUnwrappedOptional<Int>"),
            Example("let collection: AnyCollection<Int!>"),
            Example("func foo(int: Int!) {}")
        ]
    )

    private func hasImplicitlyUnwrappedOptional(_ typeName: String) -> Bool {
        return typeName.contains("!") || typeName.contains("ImplicitlyUnwrappedOptional<")
    }

    public func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard SwiftDeclarationKind.variableKinds.contains(kind) else {
            return []
        }

        guard let typeName = dictionary.typeName  else { return [] }
        guard hasImplicitlyUnwrappedOptional(typeName) else { return [] }

        if configuration.mode == .allExceptIBOutlets {
            let isOutlet = dictionary.enclosedSwiftAttributes.contains(.iboutlet)
            if isOutlet { return [] }
        }

        let location: Location
        if let offset = dictionary.offset {
            location = Location(file: file, byteOffset: offset)
        } else {
            location = Location(file: file.path)
        }

        return [
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity.severity,
                           location: location)
        ]
    }
}
