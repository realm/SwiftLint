//
//  PluginOptions.swift
//  SwiftLint
//
//  Created by Sash Zats on 6/23/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

protocol PluginsOptionsType {
    var plugins: String? { get }
}

extension PluginsOptionsType {
    var pluginPaths: [String] {
        guard let plugins = plugins else {
            return []
        }

        return plugins
            .componentsSeparatedByString(",")
            .map { $0.stringByTrimmingCharactersInSet(.whitespaceCharacterSet()) }
    }
}
