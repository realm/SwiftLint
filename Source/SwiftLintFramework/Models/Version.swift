//
//  Version.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 27/12/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public struct Version {
    public let value: String

    public static let current: Version = {
        let value = Bundle(identifier: "io.realm.SwiftLintFramework")!
            .object(forInfoDictionaryKey: "CFBundleShortVersionString")!
        // swiftlint:disable:next force_cast
        return Version(value: value as! String)
    }()
}
