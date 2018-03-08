//
//  ExplicitTypeInterfaceConfiguration.swift
//  SwiftLint
//
//  Created by Rounak Jain on 2/18/18.
//  Copyright © 2018 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

private enum VariableKind: String {
    case instance
    case local
    case `static`
    case `class`
}

private extension SwiftDeclarationKind {
    init(variableKind: VariableKind) {
        switch variableKind {
        case .instance:
            self = .varInstance
        case .local:
            self = .varLocal
        case .static:
            self = .varStatic
        case .class:
            self = .varClass
        }
    }

    var variableKind: VariableKind? {
        switch self {
        case .varInstance:
            return .instance
        case .varLocal:
            return .local
        case .varStatic:
            return .static
        case .varClass:
            return .class
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
        let excludedKinds = ExplicitTypeInterfaceConfiguration.variableKinds.subtracting(allowedKinds)
        let simplifiedExcludedKinds = excludedKinds.compactMap { $0.variableKind?.rawValue }.sorted()
        return severityConfiguration.consoleDescription + ", excluded: \(simplifiedExcludedKinds)"
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
            case ("excluded", let excludedStrings as [String]):
                let excludedKinds = excludedStrings.compactMap(VariableKind.init(rawValue:))
                allowedKinds.subtract(excludedKinds.map(SwiftDeclarationKind.init(variableKind:)))
            default:
                throw ConfigurationError.unknownConfiguration
            }
        }
    }

    public static func == (lhs: ExplicitTypeInterfaceConfiguration, rhs: ExplicitTypeInterfaceConfiguration) -> Bool {
        return lhs.allowedKinds == rhs.allowedKinds && lhs.severityConfiguration == rhs.severityConfiguration
    }

}
