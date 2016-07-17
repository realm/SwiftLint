//
//  RuleList+Plugins.swift
//  SwiftLint
//
//  Created by Sash Zats on 6/23/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SwiftLintFramework

extension RuleList {
    init(pluginPaths: [String]) {
        let rules = pluginPaths.reduce(RuleList.defaultRuleTypes) { ruleTypes, pluginPath in
            let flags = RTLD_NOW | RTLD_GLOBAL
            let handler = dlopen(pluginPath, flags)
            guard handler != nil else {
                return ruleTypes
            }
            let name = (pluginPath as NSString).lastPathComponent
            let fullName = "\(name).\(name)"
            guard let ruleType = NSClassFromString(fullName) as? Rule.Type else {
                return ruleTypes
            }
            var ruleTypes = ruleTypes
            ruleTypes.append(ruleType)
            return ruleTypes
        }
        self.init(rules: rules)
    }
}
