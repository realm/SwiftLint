//
//  ColonRule.swift
//  SwiftLint
//
//  Created by JP Simard on 5/16/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

private enum ColonKind {
    case type
    case dictionary
    case functionCall
}

public struct ColonRule: CorrectableRule, ConfigurationProviderRule {

    public var configuration = ColonConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "colon",
        name: "Colon",
        description: "Colons should be next to the identifier when specifying a type " +
                     "and next to the key in dictionary literals.",
        kind: .style,
        nonTriggeringExamples: [
            "let abc: Void\n",
            "let abc: [Void: Void]\n",
            "let abc: (Void, Void)\n",
            "let abc: ([Void], String, Int)\n",
            "let abc: [([Void], String, Int)]\n",
            "let abc: String=\"def\"\n",
            "let abc: Int=0\n",
            "let abc: Enum=Enum.Value\n",
            "func abc(def: Void) {}\n",
            "func abc(def: Void, ghi: Void) {}\n",
            "// 周斌佳年周斌佳\nlet abc: String = \"abc:\"",
            "let abc = [Void: Void]()\n",
            "let abc = [1: [3: 2], 3: 4]\n",
            "let abc = [\"string\": \"string\"]\n",
            "let abc = [\"string:string\": \"string\"]\n",
            "let abc: [String: Int]\n",
            "func foo(bar: [String: Int]) {}\n",
            "func foo() -> [String: Int] { return [:] }\n",
            "let abc: Any\n",
            "let abc: [Any: Int]\n",
            "let abc: [String: Any]\n",
            "class Foo: Bar {}\n",
            "class Foo<T: Equatable> {}\n",
            "switch foo {\n" +
            "case .bar:\n" +
            "    _ = something()\n" +
            "}\n",
            "object.method(x: 5, y: \"string\")\n",
            "object.method(x: 5, y:\n" +
            "              \"string\")",
            "object.method(5, y: \"string\")\n"
        ],
        triggeringExamples: [
            "let ↓abc:Void\n",
            "let ↓abc:  Void\n",
            "let ↓abc :Void\n",
            "let ↓abc : Void\n",
            "let ↓abc : [Void: Void]\n",
            "let ↓abc : (Void, String, Int)\n",
            "let ↓abc : ([Void], String, Int)\n",
            "let ↓abc : [([Void], String, Int)]\n",
            "let ↓abc:  (Void, String, Int)\n",
            "let ↓abc:  ([Void], String, Int)\n",
            "let ↓abc:  [([Void], String, Int)]\n",
            "let ↓abc :String=\"def\"\n",
            "let ↓abc :Int=0\n",
            "let ↓abc :Int = 0\n",
            "let ↓abc:Int=0\n",
            "let ↓abc:Int = 0\n",
            "let ↓abc:Enum=Enum.Value\n",
            "func abc(↓def:Void) {}\n",
            "func abc(↓def:  Void) {}\n",
            "func abc(↓def :Void) {}\n",
            "func abc(↓def : Void) {}\n",
            "func abc(def: Void, ↓ghi :Void) {}\n",
            "let abc = [Void↓:Void]()\n",
            "let abc = [Void↓ : Void]()\n",
            "let abc = [Void↓:  Void]()\n",
            "let abc = [Void↓ :  Void]()\n",
            "let abc = [1: [3↓ : 2], 3: 4]\n",
            "let abc = [1: [3↓ : 2], 3↓:  4]\n",
            "let abc: [↓String : Int]\n",
            "let abc: [↓String:Int]\n",
            "func foo(bar: [↓String : Int]) {}\n",
            "func foo(bar: [↓String:Int]) {}\n",
            "func foo() -> [↓String : Int] { return [:] }\n",
            "func foo() -> [↓String:Int] { return [:] }\n",
            "let ↓abc : Any\n",
            "let abc: [↓Any : Int]\n",
            "let abc: [↓String : Any]\n",
            "class ↓Foo : Bar {}\n",
            "class ↓Foo:Bar {}\n",
            "class Foo<↓T:Equatable> {}\n",
            "class Foo<↓T : Equatable> {}\n",
            "object.method(x: 5, y↓ : \"string\")\n",
            "object.method(x↓:5, y: \"string\")\n",
            "object.method(x↓:  5, y: \"string\")\n"
        ],
        corrections: [
            "let ↓abc:Void\n": "let abc: Void\n",
            "let ↓abc:  Void\n": "let abc: Void\n",
            "let ↓abc :Void\n": "let abc: Void\n",
            "let ↓abc : Void\n": "let abc: Void\n",
            "let ↓abc : [Void: Void]\n": "let abc: [Void: Void]\n",
            "let ↓abc : (Void, String, Int)\n": "let abc: (Void, String, Int)\n",
            "let ↓abc : ([Void], String, Int)\n": "let abc: ([Void], String, Int)\n",
            "let ↓abc : [([Void], String, Int)]\n": "let abc: [([Void], String, Int)]\n",
            "let ↓abc:  (Void, String, Int)\n": "let abc: (Void, String, Int)\n",
            "let ↓abc:  ([Void], String, Int)\n": "let abc: ([Void], String, Int)\n",
            "let ↓abc:  [([Void], String, Int)]\n": "let abc: [([Void], String, Int)]\n",
            "let ↓abc :String=\"def\"\n": "let abc: String=\"def\"\n",
            "let ↓abc :Int=0\n": "let abc: Int=0\n",
            "let ↓abc :Int = 0\n": "let abc: Int = 0\n",
            "let ↓abc:Int=0\n": "let abc: Int=0\n",
            "let ↓abc:Int = 0\n": "let abc: Int = 0\n",
            "let ↓abc:Enum=Enum.Value\n": "let abc: Enum=Enum.Value\n",
            "func abc(↓def:Void) {}\n": "func abc(def: Void) {}\n",
            "func abc(↓def:  Void) {}\n": "func abc(def: Void) {}\n",
            "func abc(↓def :Void) {}\n": "func abc(def: Void) {}\n",
            "func abc(↓def : Void) {}\n": "func abc(def: Void) {}\n",
            "func abc(def: Void, ↓ghi :Void) {}\n": "func abc(def: Void, ghi: Void) {}\n",
            "let abc = [Void↓:Void]()\n": "let abc = [Void: Void]()\n",
            "let abc = [Void↓ : Void]()\n": "let abc = [Void: Void]()\n",
            "let abc = [Void↓:  Void]()\n": "let abc = [Void: Void]()\n",
            "let abc = [Void↓ :  Void]()\n": "let abc = [Void: Void]()\n",
            "let abc = [1: [3↓ : 2], 3: 4]\n": "let abc = [1: [3: 2], 3: 4]\n",
            "let abc = [1: [3↓ : 2], 3↓:  4]\n": "let abc = [1: [3: 2], 3: 4]\n",
            "let abc: [↓String : Int]\n": "let abc: [String: Int]\n",
            "let abc: [↓String:Int]\n": "let abc: [String: Int]\n",
            "func foo(bar: [↓String : Int]) {}\n": "func foo(bar: [String: Int]) {}\n",
            "func foo(bar: [↓String:Int]) {}\n": "func foo(bar: [String: Int]) {}\n",
            "func foo() -> [↓String : Int] { return [:] }\n": "func foo() -> [String: Int] { return [:] }\n",
            "func foo() -> [↓String:Int] { return [:] }\n": "func foo() -> [String: Int] { return [:] }\n",
            "let ↓abc : Any\n": "let abc: Any\n",
            "let abc: [↓Any : Int]\n": "let abc: [Any: Int]\n",
            "let abc: [↓String : Any]\n": "let abc: [String: Any]\n",
            "class ↓Foo : Bar {}\n": "class Foo: Bar {}\n",
            "class ↓Foo:Bar {}\n": "class Foo: Bar {}\n",
            "class Foo<↓T:Equatable> {}\n": "class Foo<T: Equatable> {}\n",
            "class Foo<↓T : Equatable> {}\n": "class Foo<T: Equatable> {}\n",
            "object.method(x: 5, y↓ : \"string\")\n": "object.method(x: 5, y: \"string\")\n",
            "object.method(x↓:5, y: \"string\")\n": "object.method(x: 5, y: \"string\")\n",
            "object.method(x↓:  5, y: \"string\")\n": "object.method(x: 5, y: \"string\")\n"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        let violations = typeColonViolationRanges(in: file, matching: pattern).flatMap { range in
            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: configuration.severityConfiguration.severity,
                                  location: Location(file: file, characterOffset: range.location))
        }

        let dictionaryViolations: [StyleViolation]
        if configuration.applyToDictionaries {
            dictionaryViolations = validate(file: file, dictionary: file.structure.dictionary)
        } else {
            dictionaryViolations = []
        }

        return (violations + dictionaryViolations).sorted { $0.location < $1.location }
    }

    public func correct(file: File) -> [Correction] {
        let violations = correctionRanges(in: file)
        let matches = violations.filter {
            !file.ruleEnabled(violatingRanges: [$0.range], for: self).isEmpty
        }

        guard !matches.isEmpty else { return [] }
        let regularExpression = regex(pattern)
        let description = type(of: self).description
        var corrections = [Correction]()
        var contents = file.contents
        for (range, kind) in matches.reversed() {
            switch kind {
            case .type:
                contents = regularExpression.stringByReplacingMatches(in: contents,
                                                                      options: [],
                                                                      range: range,
                                                                      withTemplate: "$1: $2")
            case .dictionary, .functionCall:
                contents = contents.bridge().replacingCharacters(in: range, with: ": ")
            }

            let location = Location(file: file, characterOffset: range.location)
            corrections.append(Correction(ruleDescription: description, location: location))
        }
        file.write(contents)
        return corrections
    }

    private typealias RangeWithKind = (range: NSRange, kind: ColonKind)

    private func correctionRanges(in file: File) -> [RangeWithKind] {
        let violations: [RangeWithKind] = typeColonViolationRanges(in: file, matching: pattern).map {
            (range: $0, kind: ColonKind.type)
        }
        let dictionary = file.structure.dictionary
        let contents = file.contents.bridge()
        let dictViolations: [RangeWithKind] = dictionaryColonViolationRanges(in: file, dictionary: dictionary).flatMap {
            guard let range = contents.byteRangeToNSRange(start: $0.location, length: $0.length) else {
                return nil
            }
            return (range: range, kind: .dictionary)
        }
        let functionViolations: [RangeWithKind] = functionCallColonViolationRanges(in: file,
                                                                                   dictionary: dictionary).flatMap {
            guard let range = contents.byteRangeToNSRange(start: $0.location, length: $0.length) else {
                return nil
            }
            return (range: range, kind: .functionCall)
        }

        return (violations + dictViolations + functionViolations).sorted {
            $0.range.location < $1.range.location
        }
    }
}

extension ColonRule: ASTRule {

    /// Only returns dictionary and function calls colon violations
    public func validate(file: File, kind: SwiftExpressionKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {

        let ranges = dictionaryColonViolationRanges(in: file, kind: kind, dictionary: dictionary) +
            functionCallColonViolationRanges(in: file, kind: kind, dictionary: dictionary)

        return ranges.map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severityConfiguration.severity,
                           location: Location(file: file, byteOffset: $0.location))
        }
    }

}
