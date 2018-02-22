//
//  CyclomaticComplexityConfiguration.swift
//  SwiftLint
//
//  Created by Mike Welles on 2/9/17.
//  Copyright © 2017 Realm. All rights reserved.
//
import Foundation
import SourceKittenFramework

private enum ConfigurationKey: String {
    case warning = "warning"
    case error = "error"
    case ignoresCaseStatements = "ignores_case_statements"
}

public struct CyclomaticComplexityConfiguration: RuleConfiguration, Equatable {
    public var consoleDescription: String {
        return length.consoleDescription +
            ", \(ConfigurationKey.ignoresCaseStatements.rawValue): \(ignoresCaseStatements)"
    }

    public static let defaultComplexityStatements: Set<StatementKind> = [
        .forEach,
        .if,
        .guard,
        .for,
        .repeatWhile,
        .while,
        .case
    ]

    private(set) public var length: SeverityLevelsConfiguration

    private(set) public var complexityStatements: Set<StatementKind>

    private(set) public var ignoresCaseStatements: Bool {
        didSet {
            if ignoresCaseStatements {
                complexityStatements.remove(.case)
            } else {
                complexityStatements.insert(.case)
            }
        }
    }

    var params: [RuleParameter<Int>] {
        return length.params
    }

    public init(warning: Int, error: Int?, ignoresCaseStatements: Bool = false) {
        self.length = SeverityLevelsConfiguration(warning: warning, error: error)
        self.complexityStatements = type(of: self).defaultComplexityStatements
        self.ignoresCaseStatements = ignoresCaseStatements
    }

    private var initialConfiguration: [AnyHashable: Any] = [:]

    public mutating func apply(configuration: Any) throws {
        // is it a configuration override?
        if let configStruct = configuration as? CyclomaticComplexityConfiguration {
            return try apply(configuration: configStruct)
        }

        // it is an initial configuration (by parsing .yml)
        if let configurationArray = [Int].array(of: configuration),
            !configurationArray.isEmpty {
            let warning = configurationArray[0]
            let error = (configurationArray.count > 1) ? configurationArray[1] : nil
            length = SeverityLevelsConfiguration(warning: warning, error: error)
        } else if let configDict = configuration as? [String: Any], !configDict.isEmpty {
            initialConfiguration = configDict
            for (string, value) in configDict {
                guard let key = ConfigurationKey(rawValue: string) else {
                    throw ConfigurationError.unknownConfiguration
                }
                switch (key, value) {
                case (.error, let intValue as Int):
                    length.error = intValue
                case (.warning, let intValue as Int):
                    length.warning = intValue
                case (.ignoresCaseStatements, let boolValue as Bool):
                    ignoresCaseStatements = boolValue
                default:
                    throw ConfigurationError.unknownConfiguration
                }
            }
        } else {
            throw ConfigurationError.unknownConfiguration
        }
    }

    /// This method applies the parameter's configuration on top of self's configuration
    /// Only the explicitly set values during initialization are applied,
    /// i.e. no default values are taken over.
    /// @see https://github.com/realm/SwiftLint/issues/2058#issue-298979003 for reasoning
    ///
    /// - Parameter configuration: The nested configuration which serves as source
    /// - Throws: Can not happen. Is just here due to function overloading mechanics.
    public mutating func apply(configuration: CyclomaticComplexityConfiguration) throws {
        guard !configuration.initialConfiguration.isEmpty else {
            // nothing to do here, since no values have been configured explicitly
            // and we don't want to apply default values
            return
        }
        do {
            try apply(configuration: configuration.initialConfiguration)
        } catch let error {
            queuedFatalError("Applying the explicitly set values of nested configuration on self failed: \(error)")
        }
    }
}

public func == (lhs: CyclomaticComplexityConfiguration, rhs: CyclomaticComplexityConfiguration) -> Bool {
    return lhs.length == rhs.length &&
        lhs.ignoresCaseStatements == rhs.ignoresCaseStatements
}
