//
//  NameConfiguration.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 1/19/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public struct NameConfiguration: RuleConfiguration, Equatable {
    private var minLengthParameter: Parameter<SeverityLevelsConfiguration>
    private var maxLengthParameter: Parameter<SeverityLevelsConfiguration>
    private var excludedParameter: ArrayParameter<String>
    private var allowedSymbolsParameter: ArrayParameter<String>
    private var validatesStartWithLowercaseParameter: Parameter<Bool>
    public var parameters: [ParameterDefinition]

    var minLength: SeverityLevelsConfiguration {
        return minLengthParameter.value
    }

    var maxLength: SeverityLevelsConfiguration {
        return maxLengthParameter.value
    }

    var excluded: Set<String> {
        return Set(excludedParameter.value)
    }

    var allowedSymbols: Set<String> {
        return Set(allowedSymbolsParameter.value)
    }

    var validatesStartWithLowercase: Bool {
        return validatesStartWithLowercaseParameter.value
    }

    var minLengthThreshold: Int {
        return max(minLength.warning, minLength.error ?? minLength.warning)
    }

    var maxLengthThreshold: Int {
        return min(maxLength.warning, maxLength.error ?? maxLength.warning)
    }

    public init(minLengthWarning: Int,
                minLengthError: Int?,
                maxLengthWarning: Int,
                maxLengthError: Int?,
                excluded: [String] = [],
                allowedSymbols: [String] = [],
                validatesStartWithLowercase: Bool = true) {
        let minLength = SeverityLevelsConfiguration(warning: minLengthWarning, error: minLengthError)
        let maxLength = SeverityLevelsConfiguration(warning: maxLengthWarning, error: maxLengthError)

        minLengthParameter = Parameter(key: "min_length", default: minLength, description: "")
        maxLengthParameter = Parameter(key: "max_length", default: maxLength, description: "")
        excludedParameter = ArrayParameter(key: "excluded", default: excluded, description: "")
        allowedSymbolsParameter = ArrayParameter(key: "allowed_symbols", default: allowedSymbols, description: "")
        validatesStartWithLowercaseParameter = Parameter(key: "validates_start_with_lowercase",
                                                         default: validatesStartWithLowercase, description: "")

        parameters = [minLengthParameter, maxLengthParameter, excludedParameter,
                      allowedSymbolsParameter, validatesStartWithLowercaseParameter]
    }

    public mutating func apply(configuration: [String: Any]) throws {
        try minLengthParameter.parse(from: configuration)
        try maxLengthParameter.parse(from: configuration)
        try excludedParameter.parse(from: configuration)
        try allowedSymbolsParameter.parse(from: configuration)
        try validatesStartWithLowercaseParameter.parse(from: configuration)
    }
}

public func == (lhs: NameConfiguration, rhs: NameConfiguration) -> Bool {
    return lhs.minLength == rhs.minLength &&
           lhs.maxLength == rhs.maxLength &&
           zip(lhs.excluded, rhs.excluded).reduce(true) { $0 && ($1.0 == $1.1) } &&
           zip(lhs.allowedSymbols, rhs.allowedSymbols).reduce(true) { $0 && ($1.0 == $1.1) } &&
           lhs.validatesStartWithLowercase == rhs.validatesStartWithLowercase
}

// MARK: - ConfigurationProviderRule extensions

public extension ConfigurationProviderRule where ConfigurationType == NameConfiguration {
    func severity(forLength length: Int) -> ViolationSeverity? {
        if let minError = configuration.minLength.error, length < minError {
            return .error
        } else if let maxError = configuration.maxLength.error, length > maxError {
            return .error
        } else if length < configuration.minLength.warning ||
                  length > configuration.maxLength.warning {
            return .warning
        }
        return nil
    }
}
