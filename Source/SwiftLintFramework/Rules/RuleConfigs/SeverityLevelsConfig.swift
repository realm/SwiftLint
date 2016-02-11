//
//  SeverityLevelsConfig.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 1/19/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public struct SeverityLevelsConfig: RuleConfig, Equatable {
    public var consoleDescription: String {
        let errorString: String
        if let errorValue = error {
            errorString = ", error: \(errorValue)"
        } else {
            errorString = ""
        }
        return "warning: \(warning)" + errorString
    }

    public var shortConsoleDescription: String {
        if let errorValue = error {
            return "w/e: \(warning)/\(errorValue)"
        }
        return "w: \(warning)"
    }

    var warning: Int
    var error: Int?

    var params: [RuleParameter<Int>] {
        if let error = error {
            return [RuleParameter(severity: .Error, value: error),
                RuleParameter(severity: .Warning, value: warning)]
        }
        return [RuleParameter(severity: .Warning, value: warning)]
    }

    mutating public func applyConfiguration(configuration: AnyObject) throws {
        if let config = [Int].arrayOf(configuration) where !config.isEmpty {
            warning = config[0]
            error = (config.count > 1) ? config[1] : nil
        } else if let config = configuration as? [String: Int]
                where !config.isEmpty && Set(config.keys).isSubsetOf(["warning", "error"]) {
            warning = config["warning"] ?? warning
            error = config["error"]
        } else {
            throw ConfigurationError.UnknownConfiguration
        }
    }
}

public func == (lhs: SeverityLevelsConfig, rhs: SeverityLevelsConfig) -> Bool {
    return lhs.warning == rhs.warning && lhs.error == rhs.error
}
