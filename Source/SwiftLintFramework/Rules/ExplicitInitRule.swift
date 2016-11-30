//
//  ExplicitInitRule.swift
//  SwiftLint
//
//  Created by Matt Taube on 7/2/16.
//  Copyright (c) 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct ExplicitInitRule: ASTRule, ConfigurationProviderRule, CorrectableRule, OptInRule {

    public var configuration = SeverityConfiguration(.Warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "explicit_init",
        name: "Explicit Init",
        description: "Explicitly calling .init() should be avoided.",
        nonTriggeringExamples: [
            "import Foundation; class C: NSObject { override init() { super.init() }}", // super
            "struct S { let n: Int }; extension S { init() { self.init(n: 1) } }",      // self
            "[1].flatMap(String.init)",                   // pass init as closure
            "[String.self].map { $0.init(1) }",           // initialize from a metatype value
            "[String.self].map { type in type.init(1) }"  // initialize from a metatype value
        ],
        triggeringExamples: [
            "[1].flatMap{String↓.init($0)}",
            "[String.self].map { Type in Type↓.init(1) }"  // starting with capital assumes as type
        ],
        corrections: [
            "[1].flatMap{String.init($0)}" : "[1].flatMap{String($0)}"
        ]
    )

    public enum Kind: String {
        case expr_call = "source.lang.swift.expr.call"
        case other
        public init?(rawValue: String) {
            switch rawValue {
            case Kind.expr_call.rawValue: self = .expr_call
            default: self = .other
            }
        }
    }

    public func validateFile(
        _ file: File,
        kind: ExplicitInitRule.Kind,
        dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        return violationRangesInFile(file, kind: kind, dictionary: dictionary).map {
            StyleViolation(ruleDescription: type(of: self).description,
                severity: configuration.severity,
                location: Location(file: file, characterOffset: $0.location))
        }
    }

    private let initializerWithType = regex("^[A-Z].*\\.init$")

    private func violationRangesInFile(_ file: File, kind: ExplicitInitRule.Kind,
                                       dictionary: [String: SourceKitRepresentable]) -> [NSRange] {
        func isExpected(_ name: String) -> Bool {
            let range = NSRange(location: 0, length: name.utf16.count)
            return !["super.init", "self.init"].contains(name)
                && initializerWithType.numberOfMatches(in: name, options: [], range: range) != 0
        }

        let length = ".init".utf8.count

        guard kind == .expr_call,
            let name = dictionary["key.name"] as? String, isExpected(name),
            let nameOffset = dictionary["key.nameoffset"] as? Int64,
            let nameLength = dictionary["key.namelength"] as? Int64,
            let range = (file.contents as NSString)
                .byteRangeToNSRange(start: Int(nameOffset + nameLength) - length, length: length)
            else { return [] }
        return [range]
    }

    private func violationRangesInFile(_ file: File,
                                       dictionary: [String: SourceKitRepresentable]) -> [NSRange] {
        let substructure = dictionary["key.substructure"] as? [SourceKitRepresentable] ?? []
        return substructure.flatMap { subItem -> [NSRange] in
            guard let subDict = subItem as? [String: SourceKitRepresentable],
                let kindString = subDict["key.kind"] as? String,
                let kind = ExplicitInitRule.Kind(rawValue: kindString) else {
                    return []
            }
            return self.violationRangesInFile(file, dictionary: subDict) +
                self.violationRangesInFile(file, kind: kind, dictionary: subDict)
        }
    }

    private func violationRangesInFile(_ file: File) -> [NSRange] {
        return violationRangesInFile(file, dictionary: file.structure.dictionary).sorted { lh, rh in
            lh.location > rh.location
        }
    }

    public func correctFile(_ file: File) -> [Correction] {
        let matches = violationRangesInFile(file)
            .filter { !file.ruleEnabledViolatingRanges([$0], forRule: self).isEmpty }
        guard !matches.isEmpty else { return [] }

        let description = type(of: self).description
        var corrections = [Correction]()
        var contents = file.contents
        for range in matches {
            contents = (contents as NSString)
                .replacingCharacters(in: range, with: "")
            let location = Location(file: file, characterOffset: range.location)
            corrections.append(Correction(ruleDescription: description, location: location))
        }

        file.write(contents)
        return corrections
    }
}
