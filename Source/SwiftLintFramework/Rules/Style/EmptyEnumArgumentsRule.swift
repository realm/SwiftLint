import Foundation
import SourceKittenFramework

private func wrapInSwitch(variable: String = "foo", _ str: String) -> String {
    return  "switch \(variable) {\n" +
            "    \(str): break\n" +
            "}"
}

private func wrapInFunc(_ str: String) -> String {
    return """
    func example(foo: Foo) {
        switch foo {
        case \(str):
            break
        }
    }
    """
}

public struct EmptyEnumArgumentsRule: SubstitutionCorrectableASTRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "empty_enum_arguments",
        name: "Empty Enum Arguments",
        description: "Arguments can be omitted when matching enums with associated types if they are not used.",
        kind: .style,
        nonTriggeringExamples: [
            wrapInSwitch("case .bar"),
            wrapInSwitch("case .bar(let x)"),
            wrapInSwitch("case let .bar(x)"),
            wrapInSwitch(variable: "(foo, bar)", "case (_, _)"),
            wrapInSwitch("case \"bar\".uppercased()"),
            wrapInSwitch(variable: "(foo, bar)", "case (_, _) where !something"),
            wrapInSwitch("case (let f as () -> String)?"),
            wrapInSwitch("default")
        ],
        triggeringExamples: [
            wrapInSwitch("case .bar↓(_)"),
            wrapInSwitch("case .bar↓()"),
            wrapInSwitch("case .bar↓(_), .bar2↓(_)"),
            wrapInSwitch("case .bar↓() where method() > 2"),
            wrapInFunc("case .bar↓(_)")
        ],
        corrections: [
            wrapInSwitch("case .bar↓(_)"): wrapInSwitch("case .bar"),
            wrapInSwitch("case .bar↓()"): wrapInSwitch("case .bar"),
            wrapInSwitch("case .bar↓(_), .bar2↓(_)"): wrapInSwitch("case .bar, .bar2"),
            wrapInSwitch("case .bar↓() where method() > 2"): wrapInSwitch("case .bar where method() > 2"),
            wrapInFunc("case .bar↓(_)"): wrapInFunc("case .bar")
        ]
    )

    public func validate(file: SwiftLintFile, kind: StatementKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        return violationRanges(in: file, kind: kind, dictionary: dictionary).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    public func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String) {
        return (violationRange, "")
    }

    public func violationRanges(in file: SwiftLintFile, kind: StatementKind,
                                dictionary: SourceKittenDictionary) -> [NSRange] {
        guard kind == .case else {
            return []
        }

        let contents = file.linesContainer

        let callsRanges = dictionary.substructure.compactMap { dict -> NSRange? in
            guard dict.expressionKind == .call,
                let offset = dict.offset,
                let length = dict.length,
                let range = contents.byteRangeToNSRange(start: offset, length: length) else {
                    return nil
            }

            return range
        }

        return dictionary.elements.flatMap { subDictionary -> [NSRange] in
            guard subDictionary.kind == "source.lang.swift.structure.elem.pattern",
                let offset = subDictionary.offset,
                let length = subDictionary.length,
                let caseRange = contents.byteRangeToNSRange(start: offset, length: length) else {
                    return []
            }

            let emptyArgumentRegex = regex("\\.\\S+\\s*(\\([,\\s_]*\\))")
            return emptyArgumentRegex.matches(in: file.contents, options: [], range: caseRange).compactMap { match in
                let parenthesesRange = match.range(at: 1)

                // avoid matches after `where` keyworkd
                if let whereRange = file.match(pattern: "where", with: [.keyword], range: caseRange).first {
                    if whereRange.location < parenthesesRange.location {
                        return nil
                    }

                    // avoid matches in "(_, _) where"
                    if let whereByteRange = contents.NSRangeToByteRange(start: whereRange.location,
                                                                        length: whereRange.length),
                        case let length = whereByteRange.location - offset,
                        case let byteRange = NSRange(location: offset, length: length),
                        Set(file.syntaxMap.kinds(inByteRange: byteRange)) == [.keyword] {
                        return nil
                    }
                }

                if callsRanges.contains(where: parenthesesRange.intersects) {
                    return nil
                }

                return parenthesesRange
            }
        }
    }
}
