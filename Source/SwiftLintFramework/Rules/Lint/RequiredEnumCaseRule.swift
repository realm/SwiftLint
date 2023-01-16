import SwiftSyntax

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
struct RequiredEnumCaseRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    var configuration = RequiredEnumCaseRuleConfiguration()

    init() {}

    private static let exampleConfiguration = [
        "NetworkResponsable": ["success": "warning", "error": "warning", "notConnected": "warning"]
    ]

    static let description = RuleDescription(
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

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(configuration: configuration)
    }
}

private extension RequiredEnumCaseRule {
    final class Visitor: ViolationsSyntaxVisitor {
        private let configuration: RequiredEnumCaseRuleConfiguration

        init(configuration: RequiredEnumCaseRuleConfiguration) {
            self.configuration = configuration
            super.init(viewMode: .sourceAccurate)
        }

        override func visitPost(_ node: EnumDeclSyntax) {
            guard configuration.protocols.isNotEmpty else {
                return
            }

            let enumCases = node.enumCasesNames
            let violations = configuration.protocols
                .flatMap { type, requiredCases -> [ReasonedRuleViolation] in
                    guard node.inheritanceClause.containsInheritedType(inheritedTypes: [type]) else {
                        return []
                    }

                    return requiredCases.compactMap { requiredCase in
                        guard !enumCases.contains(requiredCase.name) else {
                            return nil
                        }

                        return ReasonedRuleViolation(
                            position: node.positionAfterSkippingLeadingTrivia,
                            reason: "Enums conforming to \"\(type)\" must have a \"\(requiredCase.name)\" case",
                            severity: requiredCase.severity
                        )
                    }
                }

            self.violations.append(contentsOf: violations)
        }
    }
}

private extension EnumDeclSyntax {
    var enumCasesNames: [String] {
        return members.members
            .flatMap { member -> [String] in
                guard let enumCaseDecl = member.decl.as(EnumCaseDeclSyntax.self) else {
                    return []
                }

                return enumCaseDecl.elements.map(\.identifier.text)
            }
    }
}
