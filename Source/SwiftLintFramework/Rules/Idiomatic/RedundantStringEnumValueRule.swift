import SourceKittenFramework

private func children(of dict: [String: SourceKitRepresentable],
                      matching kind: SwiftDeclarationKind) -> [[String: SourceKitRepresentable]] {
    return dict.substructure.compactMap { subDict in
        if let kindString = subDict.kind,
            SwiftDeclarationKind(rawValue: kindString) == kind {
            return subDict
        }
        return nil
    }
}

public struct RedundantStringEnumValueRule: ASTRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "redundant_string_enum_value",
        name: "Redundant String Enum Value",
        description: "String enum values can be omitted when they are equal to the enumcase name.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            """
            enum Numbers: String {
              case one
              case two
            }
            """,
            """
            enum Numbers: Int {
              case one = 1
              case two = 2
            }
            """,
            """
            enum Numbers: String {
              case one = "ONE"
              case two = "TWO"
            }
            """,
            """
            enum Numbers: String {
              case one = "ONE"
              case two = "two"
            }
            """,
            """
            enum Numbers: String {
              case one, two
            }
            """
        ],
        triggeringExamples: [
            """
            enum Numbers: String {
              case one = ↓"one"
              case two = ↓"two"
            }
            """,
            """
            enum Numbers: String {
              case one = ↓"one", two = ↓"two"
            }
            """,
            """
            enum Numbers: String {
              case one, two = ↓"two"
            }
            """
        ]
    )

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard kind == .enum else {
            return []
        }

        // Check if it's a String enum
        guard dictionary.inheritedTypes.contains("String") else {
            return []
        }

        let violations = violatingOffsetsForEnum(dictionary: dictionary, file: file)
        return violations.map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: $0))
        }
    }

    private func violatingOffsetsForEnum(dictionary: [String: SourceKitRepresentable], file: File) -> [Int] {
        var caseCount = 0
        var violations = [Int]()

        for enumCase in children(of: dictionary, matching: .enumcase) {
            caseCount += enumElementsCount(dictionary: enumCase)
            violations += violatingOffsetsForEnumCase(dictionary: enumCase, file: file)
        }

        guard violations.count == caseCount else {
            return []
        }

        return violations
    }

    private func enumElementsCount(dictionary: [String: SourceKitRepresentable]) -> Int {
        return children(of: dictionary, matching: .enumelement).filter({ element in
            return !filterEnumInits(dictionary: element).isEmpty
        }).count
    }

    private func violatingOffsetsForEnumCase(dictionary: [String: SourceKitRepresentable], file: File) -> [Int] {
        return children(of: dictionary, matching: .enumelement).flatMap { element -> [Int] in
            guard let name = element.name else {
                return []
            }
            return violatingOffsetsForEnumElement(dictionary: element, name: name, file: file)
        }
    }

    private func violatingOffsetsForEnumElement(dictionary: [String: SourceKitRepresentable], name: String,
                                                file: File) -> [Int] {
        let enumInits = filterEnumInits(dictionary: dictionary)

        return enumInits.compactMap { dictionary -> Int? in
            guard let offset = dictionary.offset,
                let length = dictionary.length else {
                    return nil
            }

            // the string would be quoted if offset and length were used directly
            let enumCaseName = file.contents.bridge()
                .substringWithByteRange(start: offset + 1, length: length - 2) ?? ""
            guard enumCaseName == name else {
                return nil
            }

            return offset
        }
    }

    private func filterEnumInits(dictionary: [String: SourceKitRepresentable]) -> [[String: SourceKitRepresentable]] {
        return dictionary.elements.filter {
            $0.kind == "source.lang.swift.structure.elem.init_expr"
        }
    }
}
