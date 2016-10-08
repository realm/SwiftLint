//
//  Yaml+SwiftLint.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 12/28/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation
import Yaml

extension Yaml {
    var flatDictionary: [Swift.String: Any]? {
        if let dict = dictionary {
            var newDict: [Swift.String: Any] = [:]
            for (key, value) in dict {
                newDict[key.stringValue] = value.flatValue
            }
            return newDict
        } else if count == 0 || self == .Null { // swiftlint:disable:this empty_count
            return [:]
        }

        return nil
    }

    var flatArray: [Any]? { return array?.map { $0.flatValue } }

    var flatValue: Any {
        switch self {
        case .Bool(let myBool):
            return myBool as Any
        case .Int(let myInt):
            return myInt as Any
        case .Double(let myDouble):
            return myDouble as Any
        case .String(let myString):
            return myString as Any
        case .Array:
            return flatArray! as Any // This is valid because .Array will always flatten
        case .Dictionary:
            return flatDictionary! as Any // This is valid because .Dictionary will always flatten
        case .Null:
            return NSNull()
        }
    }

    var stringValue: Swift.String {
        switch self {
        case .Bool(let myBool):
            return myBool.description
        case .Int(let myInt):
            return myInt.description
        case .Double(let myDouble):
            return myDouble.description
        case .String(let myString):
            return myString
        case .Array(let myArray):
            return myArray.description
        case .Dictionary(let myDictionary):
            return myDictionary.description
        case .Null:
            return "Null"
        }
    }
}
