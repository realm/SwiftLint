import Foundation
import SourceKittenFramework

public struct SpellingRule: ASTRule, ConfigurationProviderRule, AutomaticTestableRule {
    private struct IdentifierComponents {
        let identifier: String
        let components: [String]
        let offset: Int
    }

    public var configuration = SpellingConfiguration(allowedExtraWords: [])

    let words: Set<String>

    public init() {
        let manager = FileManager.default
        let path = "/usr/share/dict/words"

        guard manager.fileExists(atPath: path) else {
            queuedFatalError("Did not find dictionary at path: \(path)")
        }
        guard let validHandle = FileHandle(forReadingAtPath: path) else {
            queuedFatalError("Could not read file at path: \(path)")
        }
        let fileData = validHandle.readDataToEndOfFile()
        let fileString = String(data: fileData, encoding: .utf8)!

        words = Set(fileString.components(separatedBy: .newlines).map { $0.lowercased() })
    }

    public static let description = RuleDescription(
        identifier: "spell_check",
        name: "SpellCheck Rule",
        description: "Identifiers should have correct spelling.",
        kind: .style,
        nonTriggeringExamples: [
            "let number = 5",
            "let camelCaseNumber = 4",
            "let snake_case_number = 3",
            "func testRule_withUnderscore_shouldSpellCheck(label argument: Int) {\n}"
        ],
        triggeringExamples: [
            "let nuber = 5",
            "let camelCasenumber = 4",
            "let snake_casenumber = 3"
        ],
        deprecatedAliases: []
    )

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard !dictionary.enclosedSwiftAttributes.contains(.override) else {
            return []
        }

        return components(of: dictionary, kind: kind).map { identifierComponents in
            let identifier = identifierComponents.identifier
            let components = identifierComponents.components
            let offset = identifierComponents.offset
            guard !configuration.allowedExtraWords.contains(identifier) else {
                return []
            }

            let description = Swift.type(of: self).description

            let type = self.type(for: kind)

            for component in components {
                if !words.contains(component) {
                    let reason = "\(type) is not spelled correctly: '\(identifier)': '\(component)'"
                    return [
                        StyleViolation(ruleDescription: description,
                                       severity: .error,
                                       location: Location(file: file, byteOffset: offset),
                                       reason: reason)
                    ]
                }
            }

            return []
        } ?? []
    }

    private func components(of dictionary: [String: SourceKitRepresentable],
                            kind: SwiftDeclarationKind) -> IdentifierComponents? {
        guard var name = dictionary.name,
            let offset = dictionary.offset,
            kinds.contains(kind),
            !name.hasPrefix("$") else {
                return nil
        }

        if kind == .enumelement,
            SwiftVersion.current > .fourDotOne,
            let parenIndex = name.index(of: "("),
            parenIndex > name.startIndex {
            let index = name.index(before: parenIndex)
            name = String(name[...index])
        }

        let splittedName = name.split(whereSeparator: "_():".contains)
        let components = splittedName.flatMap { nameComponent in
            String(nameComponent).splitBefore { $0.isUpperCase }
        }.map { $0.lowercased() }

        return IdentifierComponents(identifier: name.nameStrippingLeadingUnderscoreIfPrivate(dictionary),
                                    components: components,
                                    offset: offset)
    }

    private let kinds: Set<SwiftDeclarationKind> = {
        return SwiftDeclarationKind.variableKinds
            .union(SwiftDeclarationKind.functionKinds)
            .union([.enumelement])
    }()

    private func type(for kind: SwiftDeclarationKind) -> String {
        if SwiftDeclarationKind.functionKinds.contains(kind) {
            return "Function"
        } else if kind == .enumelement {
            return "Enum element"
        } else {
            return "Variable"
        }
    }
}

private extension String {
    func splitBefore(separator isSeparator: (Character) throws -> Bool) rethrows -> [String] {
        var result: [String] = []
        var subSequence: String = ""

        var iterator = self.makeIterator()
        while let element = iterator.next() {
            if try isSeparator(element) {
                if !subSequence.isEmpty {
                    result.append(subSequence)
                }
                subSequence = String(element)
            } else {
                subSequence.append(element)
            }
        }
        result.append(subSequence)
        return result
    }
}

private extension Character {
    var isUpperCase: Bool {
        return String(self) == String(self).uppercased()
    }
}

public struct SpellingConfiguration: RuleConfiguration, Equatable {
    public var consoleDescription: String {
        return ""
    }

    public var allowedExtraWords: Set<String>

    public init(allowedExtraWords: [String]) {
        self.allowedExtraWords = Set(allowedExtraWords)
    }

    public mutating func apply(configuration: Any) throws {
        guard let configurationDict = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let allowedExtraWords = [String].array(of: configurationDict["allowed_extra_words"]) {
            self.allowedExtraWords = Set(allowedExtraWords)
        }
    }
}
