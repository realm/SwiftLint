//
//  FilePrivateConfiguration.swift
//  SwiftLint
//
//  Created by Jose Cheyo Jimenez on 05/02/17.
//  Copyright © 2017 Realm. All rights reserved.
//

public struct FilePrivateConfiguration: RuleConfiguration, Equatable {
    private(set) var severityConfiguration = SeverityConfiguration(.warning)
    private(set) var strict: Bool

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription + ", strict: \(strict)"
    }

    public init(strict: Bool) {
        self.strict = strict
    }

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let strict = configuration["strict"] as? Bool {
            self.strict = strict
        }

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }

    public static func == (lhs: FilePrivateConfiguration,
                           rhs: FilePrivateConfiguration) -> Bool {
        return lhs.strict == rhs.strict &&
            lhs.severityConfiguration == rhs.severityConfiguration
    }
}
