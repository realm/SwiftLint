import SourceKittenFramework

public struct SwitchCaseAlignmentRule: ASTRule, ConfigurationProviderRule {
    public var configuration = SwitchCaseAlignmentConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "switch_case_alignment",
        name: "Switch and Case Statement Alignment",
        description: "Case statements should vertically align with their enclosing switch statement, " +
                     "or indented if configured otherwise.",
        kind: .style,
        nonTriggeringExamples: Examples(indentedCases: false).nonTriggeringExamples,
        triggeringExamples: Examples(indentedCases: false).triggeringExamples
    )

    public func validate(file: SwiftLintFile, kind: StatementKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        let contents = file.stringView

        guard kind == .switch,
              let offset = dictionary.offset,
              let (_, switchCharacter) = contents.lineAndCharacter(forByteOffset: offset) else {
            return []
        }

        let caseStatements = dictionary.substructure.filter { subDict in
            // includes both `case` and `default` statements
            return subDict.statementKind == .case
        }

        if caseStatements.isEmpty {
            return []
        }

        let caseLocations = caseStatements.compactMap { caseDict -> Location? in
            guard let byteOffset = caseDict.offset,
                  let (line, char) = contents.lineAndCharacter(forByteOffset: byteOffset) else {
                return nil
            }

            return Location(file: file.path, line: line, character: char)
        }

        guard let firstCaseCharacter = caseLocations.first?.character else {
            return []
        }

        // If indented_cases is on, the first case should be indented from its containing switch.
        if configuration.indentedCases, firstCaseCharacter <= switchCharacter {
            return caseLocations.map(locationToViolation)
        }

        let indentation = configuration.indentedCases ? firstCaseCharacter - switchCharacter : 0

        return caseLocations
            .filter { $0.character != switchCharacter + indentation }
            .map(locationToViolation)
    }

    private func locationToViolation(_ location: Location) -> StyleViolation {
        let reason = """
                    Case statements should \
                    \(configuration.indentedCases ? "be indented within" : "vertically align with") \
                    their enclosing switch statement.
                    """

        return StyleViolation(ruleDescription: Self.description,
                              severity: configuration.severityConfiguration.severity,
                              location: location,
                              reason: reason)
    }
}

extension SwitchCaseAlignmentRule {
    struct Examples {
        private let indentedCasesOption: Bool
        private let violationMarker = "↓"

        init(indentedCases: Bool) {
            self.indentedCasesOption = indentedCases
        }

        var triggeringExamples: [Example] {
            return (indentedCasesOption ? nonIndentedCases : indentedCases) + invalidCases
        }

        var nonTriggeringExamples: [Example] {
            return indentedCasesOption ? indentedCases : nonIndentedCases
        }

        private var indentedCases: [Example] {
            let violationMarker = indentedCasesOption ? "" : self.violationMarker

            return [
                Example("""
                switch someBool {
                    \(violationMarker)case true:
                        print("red")
                    \(violationMarker)case false:
                        print("blue")
                }
                """),
                Example("""
                if aBool {
                    switch someBool {
                        \(violationMarker)case true:
                            print('red')
                        \(violationMarker)case false:
                            print('blue')
                    }
                }
                """),
                Example("""
                switch someInt {
                    \(violationMarker)case 0:
                        print('Zero')
                    \(violationMarker)case 1:
                        print('One')
                    \(violationMarker)default:
                        print('Some other number')
                }
                """)
            ]
        }

        private var nonIndentedCases: [Example] {
            let violationMarker = indentedCasesOption ? self.violationMarker : ""

            return [
                Example("""
                switch someBool {
                \(violationMarker)case true: // case 1
                    print('red')
                \(violationMarker)case false:
                    /*
                    case 2
                    */
                    if case let .someEnum(val) = someFunc() {
                        print('blue')
                    }
                }
                enum SomeEnum {
                    case innocent
                }
                """),
                Example("""
                if aBool {
                    switch someBool {
                    \(violationMarker)case true:
                        print('red')
                    \(violationMarker)case false:
                        print('blue')
                    }
                }
                """),
                Example("""
                switch someInt {
                // comments ignored
                \(violationMarker)case 0:
                    // zero case
                    print('Zero')
                \(violationMarker)case 1:
                    print('One')
                \(violationMarker)default:
                    print('Some other number')
                }
                """)
            ]
        }

        private var invalidCases: [Example] {
            let indentation = indentedCasesOption ? "    " : ""

            return [
                Example("""
                switch someBool {
                \(indentation)case true:
                    \(indentation)print('red')
                    \(indentation)\(violationMarker)case false:
                        \(indentation)print('blue')
                }
                """),
                Example("""
                if aBool {
                    switch someBool {
                        \(indentation)\(indentedCasesOption ? "" : violationMarker)case true:
                        \(indentation)print('red')
                    \(indentation)\(indentedCasesOption ? violationMarker : "")case false:
                    \(indentation)print('blue')
                    }
                }
                """)
            ]
        }
    }
}
