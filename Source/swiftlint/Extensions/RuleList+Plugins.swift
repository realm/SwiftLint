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
            guard let bundle = NSBundle(path: pluginPath) else {
                queuedPrintError("Failed to load the plugin at \(pluginPath)")
                return ruleTypes
            }
            if !bundle.loaded {
                bundle.load()
            }
            guard let principalClass = bundle.principalClass as? Rule.Type else {
                queuedPrintError("Plugin \"\(pluginPath)\" principal class " +
                    "\(bundle.principalClass) is not of type Rule")
                return ruleTypes
            }
            var ruleTypes = ruleTypes
            ruleTypes.append(principalClass)
            return ruleTypes
        }
        self.init(rules: rules)
    }
}
