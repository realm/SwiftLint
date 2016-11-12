//
//  Version.swift
//  SwiftLint
//
//  Created by HirayamaYuya on 2016/09/16.
//  Copyright © 2016年 Realm. All rights reserved.
//

import Foundation

public struct Version: CustomStringConvertible, Comparable {

    public static var current: Version? {
        get {
            guard let version = NSBundle(identifier: "io.realm.SwiftLintFramework")?
                .objectForInfoDictionaryKey("CFBundleShortVersionString") as? String else {
                    return nil
            }

            return Version(versionString: version)
        }
    }

    let major: Int
    let minor: Int
    let patch: Int

    init(major: Int, minor: Int = 0, patch: Int = 0) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    init?(versionString: String) {
        let _numbers = try? versionString.componentsSeparatedByString(".").map { numberStr -> Int in
            guard let number = Int(numberStr) else {
                throw NSError.init(domain: "", code: 0, userInfo: nil)
            }
            return number
        }

        guard let numbers = _numbers else {
            return nil
        }

        if numbers.isEmpty {
            return nil
        }

        if numbers.count == 3 {
            self.init(major: numbers[0], minor: numbers[1], patch: numbers[2])
        } else if numbers.count == 2 {
            self.init(major: numbers[0], minor: numbers[1], patch: 0)
        } else if numbers.count == 1 {
            self.init(major: numbers[0], minor: 0, patch: 0)
        } else {
            fatalError()
        }
    }

    public var description: String {
        return "\(major).\(minor).\(patch)"
    }
}

public func == (left: Version, right: Version) -> Bool {
    return
        left.major == right.major &&
        left.minor == right.minor &&
        left.patch == right.patch
}

public func < (left: Version, right: Version) -> Bool {
    if left == right {
        return false
    } else {
        return !(left > right)
    }
}
