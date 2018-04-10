//
//  RequiredEnumCaseRule.swift
//  SwiftLint
//
//  Created by Ritter, Donald on 9/13/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
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
    public typealias KindType = SwiftDeclarationKind
    typealias RequiredCase = RequiredEnumCaseRuleConfiguration.RequiredCase

    /// Keys needed to parse the information from the SourceKitRepresentable dictionary.
    struct Keys {
        static let offset = "key.offset"
        static let inheritedTypes = "key.inheritedtypes"
        static let name = "key.name"
        static let substructure = "key.substructure"
        static let kind = "key.kind"
        static let enumCase = "source.lang.swift.decl.enumcase"
    }

    /// Simple representation of parsed information from the SourceKitRepresentable dictionary.
    struct Enum {
        let file: File
        let location: Location
        let inheritedTypes: [String]
        let cases: [String]

        init(from dictionary: [String: SourceKitRepresentable], in file: File) {
            self.file = file
            location = Enum.location(from: dictionary, in: file)
            inheritedTypes = Enum.inheritedTypes(from: dictionary)
            cases = Enum.cases(from: dictionary)
        }

        /// Determines the location of where the enum declaration starts.
        ///
        /// - Parameters:
        ///   - dictionary: Parsed source for the enum.
        ///   - file: File that contains the enum.
        /// - Returns: Location of where the enum declaration starts.
        static func location(from dictionary: [String: SourceKitRepresentable], in file: File) -> Location {
            guard let offset = dictionary[Keys.offset] as? Int64 else {
                return Location(file: file, characterOffset: 0)
            }

            return Location(file: file, characterOffset: Int(offset))
        }

        /// Determines all of the inherited types the enum has.
        ///
        /// - Parameter dictionary: Parsed source for the enum.
        /// - Returns: All of the inherited types the enum has.
        static func inheritedTypes(from dictionary: [String: SourceKitRepresentable]) -> [String] {
            guard let inheritedTypes = dictionary[Keys.inheritedTypes] as? [SourceKitRepresentable] else {
                return []
            }

            return inheritedTypes.compactMap { $0 as? [String: SourceKitRepresentable] }.compactMap {
                $0[Keys.name] as? String
            }
        }

        /// Determines the names of cases found in the enum.
        ///
        /// - Parameter dictionary: Parsed source for the enum.
        /// - Returns: Names of cases found in the enum.
        static func cases(from dictionary: [String: SourceKitRepresentable]) -> [String] {
            guard let elements = dictionary[Keys.substructure] as? [SourceKitRepresentable] else {
                return []
            }

            let caseSubstructures = elements.compactMap { $0 as? [String: SourceKitRepresentable] }.filter {
                $0.filter {
                    $0.0 == Keys.kind && $0.1 as? String == SwiftDeclarationKind.enumcase.rawValue
                }.isEmpty == false
            }.compactMap { $0[Keys.substructure] as? [SourceKitRepresentable] }

            return caseSubstructures.flatMap { $0 }.compactMap { $0 as? [String: SourceKitRepresentable] }.compactMap {
                $0[Keys.name] as? String
            }
        }
    }

    public var configuration = RequiredEnumCaseRuleConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "required_enum_case",
        name: "Required Enum Case",
        description: "Enums conforming to a specified protocol must implement a specific case(s).",
        kind: .lint,
        nonTriggeringExamples: [
            "enum MyNetworkResponse: String, NetworkResponsable {\n" +
            "    case success, error, notConnected \n" +
            "}",
            "enum MyNetworkResponse: String, NetworkResponsable {\n" +
            "    case success, error, notConnected(error: Error) \n" +
            "}",
            "enum MyNetworkResponse: String, NetworkResponsable {\n" +
            "    case success\n" +
            "    case error\n" +
            "    case notConnected\n" +
            "}",
            "enum MyNetworkResponse: String, NetworkResponsable {\n" +
            "    case success\n" +
            "    case error\n" +
            "    case notConnected(error: Error)\n" +
            "}"
        ],
        triggeringExamples: [
            "enum MyNetworkResponse: String, NetworkResponsable {\n" +
            "    case success, error \n" +
            "}",
            "enum MyNetworkResponse: String, NetworkResponsable {\n" +
            "    case success, error \n" +
            "}",
            "enum MyNetworkResponse: String, NetworkResponsable {\n" +
            "    case success\n" +
            "    case error\n" +
            "}",
            "enum MyNetworkResponse: String, NetworkResponsable {\n" +
            "    case success\n" +
            "    case error\n" +
            "}"
        ]
    )

    public func validate(file: File, kind: KindType, dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard kind == .enum else {
            return []
        }

        return violations(for: Enum(from: dictionary, in: file))
    }

    /// Iterates over all of the protocols in the configuration and creates violations for missing cases.
    ///
    /// - Parameters:
    ///   - parsed: Enum information parsed from the SourceKitRepresentable dictionary.
    /// - Returns: Violations for missing cases.
    func violations(for parsed: Enum) -> [StyleViolation] {
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
    /// - Parameters:
    ///   - parsed: Enum information parsed from the SourceKitRepresentable dictionary.
    ///   - protocolName: Name of the protocol that is missing the case.
    ///   - requiredCase: Information about the case and the severity of the violation.
    /// - Returns: Created violation.
    func create(violationIn parsed: Enum,
                for protocolName: String,
                missing requiredCase: RequiredCase) -> StyleViolation {

        return StyleViolation(
            ruleDescription: type(of: self).description,
            severity: requiredCase.severity,
            location: parsed.location,
            reason: "Enums conforming to \"\(protocolName)\" must have a \"\(requiredCase.name)\" case")
    }
}
