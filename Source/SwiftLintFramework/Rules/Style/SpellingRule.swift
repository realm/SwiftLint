import Foundation
import SourceKittenFramework

public struct SpellingRule: ASTRule, ConfigurationProviderRule {
    public var configuration = SpellingConfiguration(allowedExtraWords: [])

    let words: Set<String>

    public init() {
        let manager = FileManager.default
        let path = "/usr/share/dict/words"

        guard manager.fileExists(atPath: path) else {
            queuedFatalError("test")
        }
        guard let validHandle = FileHandle(forReadingAtPath: path) else {
            queuedFatalError("test")
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
            "let snake_case_number = 3"
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

        return validateName(dictionary: dictionary, kind: kind).map { name, offset in
            guard !configuration.allowedExtraWords.contains(name) else {
                return []
            }

            let description = Swift.type(of: self).description

            let type = self.type(for: kind)

            let components = name.splitBefore { $0.isUpperCase }
            for component in components {
                if !words.contains(component.lowercased()) {
                    let reason = "\(type) name should be spelled correctly: '\(name)': '\(component.lowercased())'"
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

    private func validateName(dictionary: [String: SourceKitRepresentable],
                              kind: SwiftDeclarationKind) -> (name: String, offset: Int)? {
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

        return (name.nameStrippingLeadingUnderscoreIfPrivate(dictionary), offset)
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
