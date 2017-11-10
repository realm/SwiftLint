//
//  GenericTypeNameRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 12/25/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct GenericTypeNameRule: ASTRule, ConfigurationProviderRule {
    public var configuration = NameConfiguration(minLengthWarning: 1,
                                                 minLengthError: 0,
                                                 maxLengthWarning: 20,
                                                 maxLengthError: 1000)

    public init() {}

    public static let description = RuleDescription(
        identifier: "generic_type_name",
        name: "Generic Type Name",
        description: "Generic type name should only contain alphanumeric characters, start with an " +
                     "uppercase character and span between 1 and 20 characters in length.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            "func foo<T>() {}\n",
            "func foo<T>() -> T {}\n",
            "func foo<T, U>(param: U) -> T {}\n",
            "func foo<T: Hashable, U: Rule>(param: U) -> T {}\n",
            "struct Foo<T> {}\n",
            "class Foo<T> {}\n",
            "enum Foo<T> {}\n",
            "func run(_ options: NoOptions<CommandantError<()>>) {}\n",
            "func foo(_ options: Set<type>) {}\n",
            "func < <T: Comparable>(lhs: T?, rhs: T?) -> Bool\n",
            "func configureWith(data: Either<MessageThread, (project: Project, backing: Backing)>)\n",
            "typealias StringDictionary<T> = Dictionary<String, T>\n",
            "typealias BackwardTriple<T1, T2, T3> = (T3, T2, T1)\n",
            "typealias DictionaryOfStrings<T : Hashable> = Dictionary<T, String>\n"
        ],
        triggeringExamples: [
            "func foo<↓T_Foo>() {}\n",
            "func foo<T, ↓U_Foo>(param: U_Foo) -> T {}\n",
            "func foo<↓\(String(repeating: "T", count: 21))>() {}\n",
            "func foo<↓type>() {}\n",
            "typealias StringDictionary<↓T_Foo> = Dictionary<String, T_Foo>\n",
            "typealias BackwardTriple<T1, ↓T2_Bar, T3> = (T3, T2_Bar, T1)\n",
            "typealias DictionaryOfStrings<↓T_Foo: Hashable> = Dictionary<T, String>\n"
        ] + ["class", "struct", "enum"].flatMap { type -> [String] in
            return [
                "\(type) Foo<↓T_Foo> {}\n",
                "\(type) Foo<T, ↓U_Foo> {}\n",
                "\(type) Foo<↓T_Foo, ↓U_Foo> {}\n",
                "\(type) Foo<↓\(String(repeating: "T", count: 21))> {}\n",
                "\(type) Foo<↓type> {}\n"
            ]
        }
    )

    private let genericTypePattern = "<(\\s*\\w.*?)>"
    private var genericTypeRegex: NSRegularExpression {
        return regex(genericTypePattern)
    }

    public func validate(file: File) -> [StyleViolation] {
        return validate(file: file, dictionary: file.structure.dictionary) +
            validateGenericTypeAliases(in: file)
    }

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        let types = genericTypesForType(in: file, kind: kind, dictionary: dictionary) +
                genericTypesForFunction(in: file, kind: kind, dictionary: dictionary)

        return types.flatMap { validate(name: $0.0, file: file, offset: $0.1) }
    }

    private func validateGenericTypeAliases(in file: File) -> [StyleViolation] {
        let pattern = "typealias\\s+\\w+?\\s*" + genericTypePattern + "\\s*="
        return file.match(pattern: pattern).flatMap { range, tokens -> [(String, Int)] in
            guard tokens.first == .keyword,
                Set(tokens.dropFirst()) == [.identifier],
                let match = genericTypeRegex.firstMatch(in: file.contents, options: [],
                                                        range: range)?.range(at: 1) else {
                    return []
            }

            let genericConstraint = file.contents.bridge().substring(with: match)
            return extractTypes(fromGenericConstraint: genericConstraint, offset: match.location, file: file)
        }.flatMap { validate(name: $0.0, file: file, offset: $0.1) }
    }

    private func genericTypesForType(in file: File, kind: SwiftDeclarationKind,
                                     dictionary: [String: SourceKitRepresentable]) -> [(String, Int)] {
        guard SwiftDeclarationKind.typeKinds.contains(kind),
            let nameOffset = dictionary.nameOffset,
            let nameLength = dictionary.nameLength,
            let bodyOffset = dictionary.bodyOffset,
            case let contents = file.contents.bridge(),
            case let start = nameOffset + nameLength,
            case let length = bodyOffset - start,
            let range = contents.byteRangeToNSRange(start: start, length: length),
            let match = genericTypeRegex.firstMatch(in: file.contents, options: [], range: range)?.range(at: 1) else {
                return []
        }

        let genericConstraint = contents.substring(with: match)
        return extractTypes(fromGenericConstraint: genericConstraint, offset: match.location, file: file)
    }

    private func genericTypesForFunction(in file: File, kind: SwiftDeclarationKind,
                                         dictionary: [String: SourceKitRepresentable]) -> [(String, Int)] {
        guard SwiftDeclarationKind.functionKinds.contains(kind),
            let offset = dictionary.nameOffset,
            let length = dictionary.nameLength,
            case let contents = file.contents.bridge(),
            let range = contents.byteRangeToNSRange(start: offset, length: length),
            let match = genericTypeRegex.firstMatch(in: file.contents, options: [], range: range)?.range(at: 1),
            match.location < minParameterOffset(parameters: dictionary.enclosedVarParameters, file: file) else {
            return []
        }

        let genericConstraint = contents.substring(with: match)
        return extractTypes(fromGenericConstraint: genericConstraint, offset: match.location, file: file)
    }

    private func minParameterOffset(parameters: [[String: SourceKitRepresentable]], file: File) -> Int {
        let offsets = parameters.flatMap { param -> Int? in
            return param.offset.flatMap {
                file.contents.bridge().byteRangeToNSRange(start: $0, length: 0)?.location
            }
        }

        return offsets.min() ?? .max
    }

    private func extractTypes(fromGenericConstraint constraint: String, offset: Int, file: File) -> [(String, Int)] {
        guard let beforeWhere = constraint.components(separatedBy: "where").first else {
            return []
        }

        let namesAndRanges: [(String, NSRange)] = beforeWhere.split(separator: ",").flatMap { string, range in
            return string.split(separator: ":").first.map {
                let (trimmed, trimmedRange) = $0.0.trimmingWhitespaces()
                return (trimmed, NSRange(location: range.location + trimmedRange.location,
                                         length: trimmedRange.length))
            }
        }

        let contents = file.contents.bridge()
        return namesAndRanges.flatMap { name, range -> (String, Int)? in
            guard let byteRange = contents.NSRangeToByteRange(start: range.location + offset,
                                                              length: range.length),
                file.syntaxMap.kinds(inByteRange: byteRange) == [.identifier] else {
                    return nil
            }

            return (name, byteRange.location)
        }
    }

    private func validate(name: String, file: File, offset: Int) -> [StyleViolation] {
        guard !configuration.excluded.contains(name) else {
            return []
        }

        let allowedSymbols = configuration.allowedSymbols.union(.alphanumerics)
        if !allowedSymbols.isSuperset(of: CharacterSet(charactersIn: name)) {
            return [
                StyleViolation(ruleDescription: type(of: self).description,
                               severity: .error,
                               location: Location(file: file, byteOffset: offset),
                               reason: "Generic type name should only contain alphanumeric characters: '\(name)'")
            ]
        } else if configuration.validatesStartWithLowercase &&
            !String(name[name.startIndex]).isUppercase() {
            return [
                StyleViolation(ruleDescription: type(of: self).description,
                               severity: .error,
                               location: Location(file: file, byteOffset: offset),
                               reason: "Generic type name should start with an uppercase character: '\(name)'")
            ]
        } else if let severity = severity(forLength: name.count) {
            return [
                StyleViolation(ruleDescription: type(of: self).description,
                               severity: severity,
                               location: Location(file: file, byteOffset: offset),
                               reason: "Generic type name should be between \(configuration.minLengthThreshold) and " +
                                        "\(configuration.maxLengthThreshold) characters long: '\(name)'")
            ]
        }

        return []
    }
}

private extension String {
    func split(separator: String) -> [(String, NSRange)] {
        let separatorLength = separator.bridge().length
        var previousEndOffset = 0
        var result = [(String, NSRange)]()

        for component in components(separatedBy: separator) {
            let length = component.bridge().length
            let range = NSRange(location: previousEndOffset, length: length)
            result.append((component, range))
            previousEndOffset += length + separatorLength
        }

        return result
    }

    func trimmingWhitespaces() -> (String, NSRange) {
        let bridged = bridge()
        let range = NSRange(location: 0, length: bridged.length)
        guard let match = regex("^\\s*(\\S*)\\s*$").firstMatch(in: self, options: [], range: range),
            NSEqualRanges(range, match.range) else {
            return (self, range)
        }

        let trimmedRange = match.range(at: 1)
        return (bridged.substring(with: trimmedRange), trimmedRange)
    }
}
