import Foundation
import SourceKittenFramework

public struct SwitchCaseAlignmentRule: ASTRule, ConfigurationProviderRule {
    public var configuration = SwitchCaseAlignmentConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "switch_case_alignment",
        name: "Switch and Case Statement Alignment",
        description: "Case statements should vertically align with the enclosing switch statement, " +
                     "or indented if configured otherwise.",
        kind: .style,
        nonTriggeringExamples: Examples.nonIndentedCases,
        triggeringExamples: Examples.indentedCases
    )

    public func validate(file: File, kind: StatementKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        let contents = file.contents.bridge()

        guard kind == .switch,
              let offset = dictionary.offset,
              let (_, switchCharacter) = contents.lineAndCharacter(forByteOffset: offset) else {
            return []
        }

        let caseStatements = dictionary.substructure.filter { subDict in
            // includes both `case` and `default` statements
            return subDict.kind.flatMap(StatementKind.init) == .case
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

        guard let firstCase = caseLocations.first,
              let firstCaseCharacter = firstCase.character else {
            return []
        }

        // If indent_cases is on, the first case should be indented from its containing switch.
        if configuration.indentedCases, firstCaseCharacter <= switchCharacter {
            return [StyleViolation(ruleDescription: type(of: self).description,
                                   severity: configuration.severityConfiguration.severity,
                                   location: firstCase)]
        }

        let indentation = configuration.indentedCases ? firstCaseCharacter - switchCharacter : 0

        return caseLocations
            .filter { $0.character != switchCharacter + indentation }
            .map {
                StyleViolation(ruleDescription: type(of: self).description,
                               severity: configuration.severityConfiguration.severity,
                               location: $0)
            }
    }
}

public extension SwitchCaseAlignmentRule {
    struct Examples {
        static public let indentedCases = [
            """
            switch someBool {
                case true:
                    print("red")
                case false:
                    print("blue")
            }
            """,
            """
            if aBool {
                switch someBool {
                    case true:
                        print('red')
                    case false:
                        print('blue')
                }
            }
            """,
            """
            switch someInt {
                case 0:
                    print('Zero')
                case 1:
                    print('One')
                default:
                    print('Some other number')
            }
            """
        ]


        static public let nonIndentedCases = [
            """
            switch someBool {
            case true: // case 1
                print('red')
            case false:
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
            """,
            """
            if aBool {
                switch someBool {
                case true:
                    print('red')
                case false:
                    print('blue')
                }
            }
            """,
            """
            switch someInt {
            // comments ignored
            case 0:
                // zero case
                print('Zero')
            case 1:
                print('One')
            default:
                print('Some other number')
            }
            """
        ]
    }
}
