import SourceKittenFramework

public struct DiscouragedDefaultSwitchCaseRule: ASTRule, OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
    // MARK: - Properties

    public var configuration = SeverityConfiguration(.error)

    public static let description = RuleDescription(
        identifier: "discouraged_default_switch_case",
        name: "Discouraged Default Switch Case",
        description: "Discouraged default switch case for enums.",
        kind: .lint,
        nonTriggeringExamples: [
            Example(
                #"""
                enum StateOfMatter {
                    case liquid
                    case solid
                    case gas
                    case plasm

                    var description: String {
                        switch self {
                            case .liquid: return "Liquid"
                            case .solid: return "Solid"
                            case .gas: return "Gas"
                            case .plasm: return "Plasm"
                        }
                    }
                }
                """#
            ),
            Example(
                #"""
                switch number {
                    case 1...4: return "Number is less than 5"
                    case 5: return "Number is 5"
                    default: return "Number is greater than 5"
                }
                """#
            ),
            Example(
                #"""
                switch text {
                    case "Welcome": return true
                    case "Goodbye": return false
                    default: return nil
                }
                """#
            ),
            Example(
                #"""
                switch value {
                    case .one: return "One"
                    case .two: return "Two"
                    case .default: return "Default"
                }
                """#
            ),
            Example(
                #"""
                switch result {
                    case .success(let value): print(value)
                    case .failure(let error): print(error)
                }
                """#
            ),
            Example(
                #"""
                switch (status, value) {
                    case (.on, .green): return true
                    default: return false
                }
                """#
            )
        ],
        triggeringExamples: [
            Example(
                #"""
                enum StateOfMatter {
                    case liquid
                    case solid
                    case gas
                    case plasm

                    var description: String {
                        switch self {
                            case .liquid: return "Liquid"
                            case .solid: return "Solid"
                            ↓default: return "Other stuff"
                        }
                    }
                }
                """#
            ),
            Example(
                #"""
                switch CLLocationManager.authorizationStatus() {
                    case .authorizedAlways, .authorizedWhenInUse, .notDetermined: return "authorized"
                    case .denied, .restricted: return "denied"
                    @unknown ↓default: fatalError("Unhandled case!")
                }
                """#
            ),
            Example(
                #"""
                switch result {
                    case .success(let value): print(value)
                    ↓default: print("Unhandled case!")
                }
                """#
            )
        ]
    )

    // MARK: - Nested type

    private typealias EnumSwitchCase = (offset: ByteCount, content: String)

    // MARK: - Life cycle

    public init() {}

    // MARK: - Public

    public func validate(file: SwiftLintFile,
                         kind: StatementKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard
            kind == .switch,
            case let allCases = allSwitchCases(in: dictionary, file: file),
            case let enumCases = allCases.filter({ $0.content.hasPrefix(".") }),
            case let defaultCase = allCases.filter({ $0.content == "default" }),
            defaultCase.count == 1,
            enumCases.count == allCases.count - 1,
            let offSet = defaultCase.first?.offset
        else {
            return []
        }

        return [
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: offSet))
        ]
    }

    // MARK: - Private

    private func allSwitchCases(in switchDictionary: SourceKittenDictionary,
                                file: SwiftLintFile) -> [EnumSwitchCase] {
        switchDictionary.substructure
            .filter { element in
                element.kind == StatementKind.case.rawValue
            }
            .flatMap { caseStatement in
                caseStatement.elements.compactMap { caseElement -> EnumSwitchCase? in
                    guard
                        let offset = caseElement.offset,
                        let length = caseElement.length,
                        case let byteRange = ByteRange(location: offset, length: length),
                        let string = file.stringView.substringWithByteRange(byteRange)
                    else {
                        return nil
                    }

                    return (offset, string)
                }
            }
    }
}
