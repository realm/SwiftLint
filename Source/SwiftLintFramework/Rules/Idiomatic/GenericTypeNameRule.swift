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
            Example("func foo<T>() {}\n"),
            Example("func foo<T>() -> T {}\n"),
            Example("func foo<T, U>(param: U) -> T {}\n"),
            Example("func foo<T: Hashable, U: Rule>(param: U) -> T {}\n"),
            Example("struct Foo<T> {}\n"),
            Example("class Foo<T> {}\n"),
            Example("enum Foo<T> {}\n"),
            Example("func run(_ options: NoOptions<CommandantError<()>>) {}\n"),
            Example("func foo(_ options: Set<type>) {}\n"),
            Example("func < <T: Comparable>(lhs: T?, rhs: T?) -> Bool\n"),
            Example("func configureWith(data: Either<MessageThread, (project: Project, backing: Backing)>)\n"),
            Example("typealias StringDictionary<T> = Dictionary<String, T>\n"),
            Example("typealias BackwardTriple<T1, T2, T3> = (T3, T2, T1)\n"),
            Example("typealias DictionaryOfStrings<T : Hashable> = Dictionary<T, String>\n")
        ],
        triggeringExamples: [
            Example("func foo<↓T_Foo>() {}\n"),
            Example("func foo<T, ↓U_Foo>(param: U_Foo) -> T {}\n"),
            Example("func foo<↓\(String(repeating: "T", count: 21))>() {}\n"),
            Example("func foo<↓type>() {}\n"),
            Example("typealias StringDictionary<↓T_Foo> = Dictionary<String, T_Foo>\n"),
            Example("typealias BackwardTriple<T1, ↓T2_Bar, T3> = (T3, T2_Bar, T1)\n"),
            Example("typealias DictionaryOfStrings<↓T_Foo: Hashable> = Dictionary<T_Foo, String>\n")
        ] + ["class", "struct", "enum"].flatMap { type -> [Example] in
            return [
                Example("\(type) Foo<↓T_Foo> {}\n"),
                Example("\(type) Foo<T, ↓U_Foo> {}\n"),
                Example("\(type) Foo<↓T_Foo, ↓U_Foo> {}\n"),
                Example("\(type) Foo<↓\(String(repeating: "T", count: 21))> {}\n"),
                Example("\(type) Foo<↓type> {}\n")
            ]
        }
    )

    private let shouldUseLegacyImplementation = SwiftVersion.current < .fourDotTwo

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        if shouldUseLegacyImplementation {
            return validate(file: file, dictionary: file.structureDictionary) +
                validateGenericTypeAliases(in: file)
        } else {
            return validate(file: file, dictionary: file.structureDictionary)
        }
    }

    public func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        if shouldUseLegacyImplementation {
            let types = genericTypesForType(in: file, kind: kind, dictionary: dictionary) +
                genericTypesForFunction(in: file, kind: kind, dictionary: dictionary)

            return types.flatMap { validate(name: $0.0, file: file, offset: $0.1) }
        } else {
            guard kind == .genericTypeParam,
                let name = dictionary.name,
                let offset = dictionary.offset
            else {
                return []
            }

            return validate(name: name, file: file, offset: offset)
        }
    }

    private func validate(name: String, file: SwiftLintFile, offset: ByteCount) -> [StyleViolation] {
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

// MARK: - Legacy Implementation

extension GenericTypeNameRule {
    private static let genericTypePattern = "<(\\s*\\w.*?)>"
    private static let genericTypeRegex = regex(genericTypePattern)

    private func validateGenericTypeAliases(in file: SwiftLintFile) -> [StyleViolation] {
        let pattern = "typealias\\s+\\w+?\\s*" + type(of: self).genericTypePattern + "\\s*="
        return file.match(pattern: pattern).flatMap { range, tokens -> [(String, ByteCount)] in
            guard tokens.first == .keyword,
                Set(tokens.dropFirst()) == [.identifier],
                let match = type(of: self).genericTypeRegex.firstMatch(in: file.contents, options: [],
                                                                       range: range)?.range(at: 1) else {
                    return []
            }

            let genericConstraint = file.stringView.substring(with: match)
            return extractTypes(fromGenericConstraint: genericConstraint, offset: match.location, file: file)
        }.flatMap { validate(name: $0.0, file: file, offset: $0.1) }
    }

    private func genericTypesForType(in file: SwiftLintFile, kind: SwiftDeclarationKind,
                                     dictionary: SourceKittenDictionary) -> [(String, ByteCount)] {
        guard SwiftDeclarationKind.typeKinds.contains(kind),
            let nameOffset = dictionary.nameOffset,
            let nameLength = dictionary.nameLength,
            let bodyOffset = dictionary.bodyOffset,
            case let contents = file.stringView,
            case let start = nameOffset + nameLength,
            case let length = bodyOffset - start,
            case let byteRange = ByteRange(location: start, length: length),
            let range = file.stringView.byteRangeToNSRange(byteRange),
            let match = type(of: self).genericTypeRegex.firstMatch(in: file.contents, options: [],
                                                                   range: range)?.range(at: 1) else {
                return []
        }

        let genericConstraint = contents.substring(with: match)
        return extractTypes(fromGenericConstraint: genericConstraint, offset: match.location, file: file)
    }

    private func genericTypesForFunction(in file: SwiftLintFile, kind: SwiftDeclarationKind,
                                         dictionary: SourceKittenDictionary) -> [(String, ByteCount)] {
        guard SwiftDeclarationKind.functionKinds.contains(kind),
            let offset = dictionary.nameOffset,
            let length = dictionary.nameLength,
            case let contents = file.stringView,
            case let byteRange = ByteRange(location: offset, length: length),
            let range = contents.byteRangeToNSRange(byteRange),
            let match = type(of: self).genericTypeRegex.firstMatch(in: file.contents,
                                                                   options: [], range: range)?.range(at: 1),
            match.location < minParameterOffset(parameters: dictionary.enclosedVarParameters, file: file)
        else {
            return []
        }

        let genericConstraint = contents.substring(with: match)
        return extractTypes(fromGenericConstraint: genericConstraint, offset: match.location, file: file)
    }

    private func minParameterOffset(parameters: [SourceKittenDictionary], file: SwiftLintFile) -> Int {
        let offsets = parameters.compactMap { param -> Int? in
            return param.offset.flatMap {
                file.stringView.byteRangeToNSRange(ByteRange(location: $0, length: 0))?.location
            }
        }

        return offsets.min() ?? .max
    }

    private func extractTypes(fromGenericConstraint constraint: String, offset: Int,
                              file: SwiftLintFile) -> [(String, ByteCount)] {
        guard let beforeWhere = constraint.components(separatedBy: "where").first else {
            return []
        }

        let namesAndRanges: [(String, NSRange)] = beforeWhere.split(separator: ",").compactMap { string, range in
            return string.split(separator: ":").first.map {
                let (trimmed, trimmedRange) = $0.0.trimmingWhitespaces()
                return (trimmed, NSRange(location: range.location + trimmedRange.location,
                                         length: trimmedRange.length))
            }
        }

        let contents = file.stringView
        return namesAndRanges.compactMap { name, range -> (String, ByteCount)? in
            guard let byteRange = contents.NSRangeToByteRange(start: range.location + offset,
                                                              length: range.length),
                file.syntaxMap.kinds(inByteRange: byteRange) == [.identifier] else {
                    return nil
            }

            return (name, byteRange.location)
        }
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
            NSEqualRanges(range, match.range)
        else {
            return (self, range)
        }

        let trimmedRange = match.range(at: 1)
        return (bridged.substring(with: trimmedRange), trimmedRange)
    }
}
