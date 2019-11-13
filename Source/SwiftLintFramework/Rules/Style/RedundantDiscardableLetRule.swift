import Foundation
import SourceKittenFramework

public struct RedundantDiscardableLetRule: SubstitutionCorrectableRule, ConfigurationProviderRule,
                                           AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "redundant_discardable_let",
        name: "Redundant Discardable Let",
        description: "Prefer `_ = foo()` over `let _ = foo()` when discarding a result from a function.",
        kind: .style,
        nonTriggeringExamples: [
            "_ = foo()\n",
            "if let _ = foo() { }\n",
            "guard let _ = foo() else { return }\n",
            "let _: ExplicitType = foo()",
            "while let _ = SplashStyle(rawValue: maxValue) { maxValue += 1 }\n"
        ],
        triggeringExamples: [
            "↓let _ = foo()\n",
            "if _ = foo() { ↓let _ = bar() }\n"
        ],
        corrections: [
            "↓let _ = foo()\n": "_ = foo()\n",
            "if _ = foo() { ↓let _ = bar() }\n": "if _ = foo() { _ = bar() }\n"
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        return violationRanges(in: file).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    public func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String) {
        return (violationRange, "_")
    }

    public func violationRanges(in file: SwiftLintFile) -> [NSRange] {
        let contents = file.linesContainer
        return file.match(pattern: "let\\s+_\\b", with: [.keyword, .keyword]).filter { range in
            guard let byteRange = contents.NSRangeToByteRange(start: range.location, length: range.length) else {
                return false
            }

            return !isInBooleanCondition(byteOffset: byteRange.location,
                                         dictionary: file.structureDictionary)
                && !hasExplicitType(utf16Range: range.location ..< range.location + range.length,
                                    fileContents: contents.nsString)
        }
    }

    private func isInBooleanCondition(byteOffset: Int, dictionary: SourceKittenDictionary) -> Bool {
        guard let offset = dictionary.offset,
            let byteRange = dictionary.length.map({ NSRange(location: offset, length: $0) }),
            NSLocationInRange(byteOffset, byteRange) else {
                return false
        }

        let kinds: Set<StatementKind> = [.if, .guard, .while]
        if let kind = dictionary.statementKind, kinds.contains(kind) {
            let conditionKind = "source.lang.swift.structure.elem.condition_expr"
            for element in dictionary.elements where element.kind == conditionKind {
                guard let elementOffset = element.offset,
                    let elementRange = element.length.map({ NSRange(location: elementOffset, length: $0) }),
                    NSLocationInRange(byteOffset, elementRange) else {
                        continue
                }

                return true
            }
        }

        for subDict in dictionary.substructure where
            isInBooleanCondition(byteOffset: byteOffset, dictionary: subDict) {
                return true
        }

        return false
    }

    private func hasExplicitType(utf16Range: Range<Int>, fileContents: NSString) -> Bool {
        guard utf16Range.upperBound != fileContents.length else {
            return false
        }
        let nextUTF16Unit = fileContents.substring(with: NSRange(location: utf16Range.upperBound, length: 1))
        return nextUTF16Unit == ":"
    }
}
