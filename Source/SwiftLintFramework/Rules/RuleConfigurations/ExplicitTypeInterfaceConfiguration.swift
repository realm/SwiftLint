//
//  ExplicitTypeInterfaceConfiguration.swift
//  SwiftLintFramework
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
    public var severityConfiguration = SeverityConfiguration(.warning)

    var allowedKinds: Set<SwiftDeclarationKind> = [.varInstance,
                                                   .varLocal,
                                                   .varStatic,
                                                   .varClass]

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription + ", allowed kinds: \(allowedKinds)"
    }
    
    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }
        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
        if let exclusion = configuration["excluded"] as? [String] {
            let excludedTypes = exclusion.flatMap(SwiftDeclarationKind.init(excludedVar:))
            allowedKinds.subtract(excludedTypes)
        }
    }
    
    public static func == (lhs: ExplicitTypeInterfaceConfiguration, rhs: ExplicitTypeInterfaceConfiguration) -> Bool {
        return lhs.allowedKinds == rhs.allowedKinds && lhs.severityConfiguration == rhs.severityConfiguration
    }
    

}
