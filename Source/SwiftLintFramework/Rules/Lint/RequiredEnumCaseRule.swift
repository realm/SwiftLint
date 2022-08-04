import SourceKittenFramework

/// Allows for Enums that conform to a protocol to require that a specific case be present.
///
/// This is primarily for result enums where a specific case is common but cannot be inherited due to cases not being
/// inheritable.
///
/// For example: A result enum is used to define all of the responses a client must handle from a specific service call
/// in an API.
///
/// ````
/// enum MyServiceCallResponse: String {
///     case unauthorized
///     case unknownError
///     case accountCreated
/// }
///
/// // An exhaustive switch can be used so any new scenarios added cause compile errors.
/// switch response {
///    case unauthorized:
///        ...
///    case unknownError:
///        ...
///    case accountCreated:
///        ...
/// }
/// ````
///
/// If cases could be inherited you could put all of the common ones in an enum and then inherit from that enum:
///
/// ````
/// enum MyServiceResponse: String {
///     case unauthorized
///     case unknownError
/// }
///
/// enum MyServiceCallResponse: MyServiceResponse {
///     case accountCreated
/// }
/// ````
///
/// Which would result in MyServiceCallResponse having all of the cases when compiled:
///
/// ```
/// enum MyServiceCallResponse: MyServiceResponse {
///     case unauthorized
///     case unknownError
///     case accountCreated
/// }
/// ```
///
/// Since that cannot be done this rule allows you to define cases that should be present if conforming to a protocol.
///
/// `.swiftlint.yml`
/// ````
/// required_enum_case:
///   MyServiceResponse:
///     unauthorized: error
///     unknownError: error
/// ````
///
/// ````
/// protocol MyServiceResponse {}
///
/// // This will now have errors because `unauthorized` and `unknownError` are not present.
/// enum MyServiceCallResponse: String, MyServiceResponse {
///     case accountCreated
/// }
/// ````
public struct RequiredEnumCaseRule: ASTRule, OptInRule, ConfigurationProviderRule {
    private typealias RequiredCase = RequiredEnumCaseRuleConfiguration.RequiredCase

    /// Simple representation of parsed information from the SourceKitRepresentable dictionary.
    private struct Enum {
        let location: Location
        let inheritedTypes: [String]
        let cases: [String]

        init(from dictionary: SourceKittenDictionary, in file: SwiftLintFile) {
            location = Self.location(from: dictionary, in: file)
            inheritedTypes = dictionary.inheritedTypes
            cases = Self.cases(from: dictionary)
        }

        /// Determines the location of where the enum declaration starts.
        ///
        /// - parameter dictionary: Parsed source for the enum.
        /// - parameter file:       `SwiftLintFile` that contains the enum.
        ///
        /// - returns: Location of where the enum declaration starts.
        static func location(from dictionary: SourceKittenDictionary, in file: SwiftLintFile) -> Location {
            return Location(file: file, byteOffset: dictionary.offset ?? 0)
        }

        /// Determines the names of cases found in the enum.
        ///
        /// - parameter dictionary: Parsed source for the enum.
        /// - returns: Names of cases found in the enum.
        static func cases(from dictionary: SourceKittenDictionary) -> [String] {
            let caseSubstructures = dictionary.substructure.filter { dict in
                return dict.declarationKind == .enumcase
            }.flatMap { $0.substructure }

            return caseSubstructures.compactMap { $0.name }.map { name in
                if let parenIndex = name.firstIndex(of: "("),
                    parenIndex > name.startIndex {
                    let index = name.index(before: parenIndex)
                    return String(name[...index])
                } else {
                    return name
                }
            }
        }
    }

    public var configuration = RequiredEnumCaseRuleConfiguration()

    public init() {}

    private static let exampleConfiguration = [
        "NetworkResponsable": ["success": "warning", "error": "warning", "notConnected": "warning"]
    ]

    public static let description = RuleDescription(
        identifier: "required_enum_case",
        name: "Required Enum Case",
        description: "Enums conforming to a specified protocol must implement a specific case(s).",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
            enum MyNetworkResponse: String, NetworkResponsable {
                case success, error, notConnected
            }
            """, configuration: exampleConfiguration),
            Example("""
            enum MyNetworkResponse: String, NetworkResponsable {
                case success, error, notConnected(error: Error)
            }
            """, configuration: exampleConfiguration),
            Example("""
            enum MyNetworkResponse: String, NetworkResponsable {
                case success
                case error
                case notConnected
            }
            """, configuration: exampleConfiguration),
            Example("""
            enum MyNetworkResponse: String, NetworkResponsable {
                case success
                case error
                case notConnected(error: Error)
            }
            """, configuration: exampleConfiguration)
        ],
        triggeringExamples: [
            Example("""
            ↓enum MyNetworkResponse: String, NetworkResponsable {
                case success, error
            }
            """, configuration: exampleConfiguration),
            Example("""
            ↓enum MyNetworkResponse: String, NetworkResponsable {
                case success, error
            }
            """, configuration: exampleConfiguration),
            Example("""
            ↓enum MyNetworkResponse: String, NetworkResponsable {
                case success
                case error
            }
            """, configuration: exampleConfiguration),
            Example("""
            ↓enum MyNetworkResponse: String, NetworkResponsable {
                case success
                case error
            }
            """, configuration: exampleConfiguration)
        ]
    )

    public func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard kind == .enum else {
            return []
        }

        return violations(for: Enum(from: dictionary, in: file))
    }

    /// Iterates over all of the protocols in the configuration and creates violations for missing cases.
    ///
    /// - parameter parsed: Enum information parsed from the SourceKitRepresentable dictionary.
    /// - returns: Violations for missing cases.
    private func violations(for parsed: Enum) -> [StyleViolation] {
        var violations: [StyleViolation] = []

        for (type, requiredCases) in configuration.protocols where parsed.inheritedTypes.contains(type) {
            for requiredCase in requiredCases where !parsed.cases.contains(requiredCase.name) {
                violations.append(create(violationIn: parsed, for: type, missing: requiredCase))
            }
        }

        return violations
    }

    /// Creates the violation for a missing case.
    ///
    /// - parameter parsed:       Enum information parsed from the `SourceKitRepresentable` dictionary.
    /// - parameter protocolName: Name of the protocol that is missing the case.
    /// - parameter requiredCase: Information about the case and the severity of the violation.
    ///
    /// - returns: Created violation.
    private func create(violationIn parsed: Enum,
                        for protocolName: String,
                        missing requiredCase: RequiredCase) -> StyleViolation {
        return StyleViolation(
            ruleDescription: Self.description,
            severity: requiredCase.severity,
            location: parsed.location,
            reason: "Enums conforming to \"\(protocolName)\" must have a \"\(requiredCase.name)\" case")
    }
}
