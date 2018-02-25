//
//  ExplicitTypeInterfaceConfiguration.swift
//  SwiftLint
//
//  Created by Rounak Jain on 2/18/18.
//  Copyright © 2018 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

private extension SwiftDeclarationKind {
    init?(excludedVar: String) {
        switch excludedVar {
        case "instance":
            self = .varInstance
        case "local":
            self = .varLocal
        case "static":
            self = .varStatic
        case "class":
            self = .varClass
        default:
            return nil
        }
    }
}

public struct ExplicitTypeInterfaceConfiguration: RuleConfiguration, Equatable {

    private static let variableKinds: Set<SwiftDeclarationKind> = [.varInstance,
                                                                   .varLocal,
                                                                   .varStatic,
                                                                   .varClass]

    public var severityConfiguration = SeverityConfiguration(.warning)

    public var allowedKinds = ExplicitTypeInterfaceConfiguration.variableKinds

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription +
        ", excluded: [\(ExplicitTypeInterfaceConfiguration.variableKinds.subtracting(allowedKinds))]"
    }

    public init() {}

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }
        for (key, value) in configuration {
            switch (key, value) {
            case ("severity", let severityString as String):
                try severityConfiguration.apply(configuration: severityString)
            case ("excluded", let excluded as [String]):
                let excludedTypes = excluded.flatMap(SwiftDeclarationKind.init(excludedVar:))
                allowedKinds.subtract(excludedTypes)
            default:
                throw ConfigurationError.unknownConfiguration
            }
        }
    }

    public static func == (lhs: ExplicitTypeInterfaceConfiguration, rhs: ExplicitTypeInterfaceConfiguration) -> Bool {
        return lhs.allowedKinds == rhs.allowedKinds && lhs.severityConfiguration == rhs.severityConfiguration
    }

}
