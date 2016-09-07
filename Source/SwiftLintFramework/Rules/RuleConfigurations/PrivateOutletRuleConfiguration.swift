//
//  PrivateOutletRuleConfiguration
//  SwiftLint
//
//  Created by Rohan Dhaimade on 24/08/2016.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public struct PrivateOutletRuleConfiguration: RuleConfiguration, Equatable {
    var severityConfiguration = SeverityConfiguration(.Warning)
    var allowPrivateSet = false

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription + ", allow_private_set: \(allowPrivateSet)"
    }

    public init(allowPrivateSet: Bool) {
        self.allowPrivateSet = allowPrivateSet
    }

    public mutating func applyConfiguration(configuration: AnyObject) throws {
        guard let configuration = configuration as? [String: AnyObject] else {
            throw ConfigurationError.UnknownConfiguration
        }

        allowPrivateSet = (configuration["allow_private_set"] as? Bool == true)

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.applyConfiguration(severityString)
        }
    }
}

public func == (lhs: PrivateOutletRuleConfiguration,
                rhs: PrivateOutletRuleConfiguration) -> Bool {
    return lhs.allowPrivateSet == rhs.allowPrivateSet
}
