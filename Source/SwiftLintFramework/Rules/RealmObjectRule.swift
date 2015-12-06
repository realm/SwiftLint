//
//  RealmObjectRule.swift
//  SwiftLint
//
//  Created by JP Simard on 12/2/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import SourceKittenFramework
import SwiftXPC

extension String {
    private func nsrangeToIndexRange(nsrange: NSRange) -> Range<Index>? {
        let from16 = utf16.startIndex.advancedBy(nsrange.location, limit: utf16.endIndex)
        let to16 = from16.advancedBy(nsrange.length, limit: utf16.endIndex)
        if let from = Index(from16, within: self), to = Index(to16, within: self) {
            return from..<to
        }
        return nil
    }
}

private func dictArrayForDictionary(dictionary: XPCDictionary, key: String) -> [[String: String]]? {
    return (dictionary[key] as? XPCArray)?.flatMap { ($0 as? XPCDictionary) as? [String: String] }
}

private func inheritedTypesForDictionary(dictionary: XPCDictionary) -> [String] {
    return dictArrayForDictionary(dictionary, key: "key.inheritedtypes")?
        .flatMap { $0["key.name"] } ?? []
}

private func isDictionaryRealmSubclass(dictionary: XPCDictionary) -> Bool {
    return ((dictionary["key.kind"] as? String).flatMap(SwiftDeclarationKind.init) == .Class) &&
        inheritedTypesForDictionary(dictionary).contains("Object")
}

private func isDeclarationDynamic(dictionary: XPCDictionary) -> Bool {
    return dictArrayForDictionary(dictionary, key: "key.attributes")?
        .flatMap({ $0["key.attribute"] }).contains("source.decl.attribute.dynamic") ?? false
}

private enum OptionalType: String {
    case Realm = "RealmOptional"
    case Standard = "Optional"
}

private func typeOptionality(typeName: String) -> (optionalType: OptionalType?, type: String) {
    let fullRange = NSRange(location: 0, length: typeName.utf16.count)
    let getType: String -> String? = { pattern in
        if let match = regex(pattern).firstMatchInString(typeName, options: [], range: fullRange),
            range = typeName.nsrangeToIndexRange(match.rangeAtIndex(1)) {
                return typeName.substringWithRange(range)
        }
        return nil
    }
    if let type = getType("^\(OptionalType.Realm.rawValue)<(\\w+)>$") {
        return (.Realm, type)
    } else if let type = getType("^\(OptionalType.Standard.rawValue)<(\\w+)>$") {
        return (.Standard, type)
    } else if let type = getType("^([\\w<>]+)\\?$") {
        return (.Standard, type)
    }
    return (nil, typeName)
}

// Mapped from https://github.com/realm/realm-cocoa/blob/master/Realm/RLMConstants.h
private enum RealmPropertyType {
    case Int(optionalType: OptionalType?)
    case Bool(optionalType: OptionalType?)
    case Float(optionalType: OptionalType?)
    case Double(optionalType: OptionalType?)
    case String(optionalType: OptionalType?)
    case Data(optionalType: OptionalType?)
    case Any(optionalType: OptionalType?)
    case Date(optionalType: OptionalType?)
    case Object(name: Swift.String, optionalType: OptionalType?)
    case Array(name: Swift.String, optionalType: OptionalType?)

    var valid: Swift.Bool {
        switch self {
            // Primitives cannot be marked as Swift.Optional
            case Int(let optionalType) where optionalType == .Standard: return false
            case Bool(let optionalType) where optionalType == .Standard: return false
            case Float(let optionalType) where optionalType == .Standard: return false
            case Double(let optionalType) where optionalType == .Standard: return false
            case String(let optionalType) where optionalType == .Realm: return false
            case Data(let optionalType) where optionalType == .Realm: return false
            case Date(let optionalType) where optionalType == .Realm: return false
            // Object links must always be marked as Swift.Optional
            case Object(_, let optionalType) where optionalType != .Standard: return false
            // Lists can never be marked as Swift.Optional
            case Array(_, let optionalType) where optionalType != nil: return false
            default: return true
        }
    }

    init?(dictionary: XPCDictionary) {
        guard let name = dictionary["key.name"] as? Swift.String,
            typeName = dictionary["key.typename"] as? Swift.String where name != typeName else {
                // SourceKit sets the typename to the property name if the type isn't explicitly
                // defined 😞
                return nil
        }
        let (optionalType, unwrappedTypeName) = typeOptionality(typeName)
        switch unwrappedTypeName {
            case "Int", "Int8", "Int16", "Int32", "Int64": self = Int(optionalType: optionalType)
            case "Bool": self = Bool(optionalType: optionalType)
            case "Float": self = Float(optionalType: optionalType)
            case "Double": self = Double(optionalType: optionalType)
            case "String", "NSString": self = String(optionalType: optionalType)
            case "NSData": self = Data(optionalType: optionalType)
            case "AnyObject": self = Any(optionalType: optionalType)
            case "NSDate": self = Date(optionalType: optionalType)
            default: return nil
        }
    }
}

private struct RealmProperty {
    let dynamic: Bool
    let mutable: Bool
    let name: String
    let offset: Int
    let type: RealmPropertyType

    var valid: Bool {
        switch type {
            case .String(_), .Data(_), .Date(_): if !dynamic { return false }
            default: _ = () /* fallthrough */
        }
        // property can be mutable iff it is 'dynamic'
        return mutable == dynamic && type.valid
    }

    init?(dictionary: XPCDictionary) {
        guard let name = dictionary["key.name"] as? String,
            offset = (dictionary["key.offset"] as? Int64).map({ Int($0) }),
            type = RealmPropertyType(dictionary: dictionary) else {
                return nil
        }
        dynamic = isDeclarationDynamic(dictionary)
        mutable = dictionary.keys.contains("key.setter_accessibility")
        self.name = name
        self.offset = offset
        self.type = type
    }
}

private func substructure(dictionary: XPCDictionary) -> [XPCDictionary]? {
    return (dictionary["key.substructure"] as? XPCArray)?.flatMap { $0 as? XPCDictionary }
}

private func propertiesForRealmObject(object: XPCDictionary) -> [RealmProperty] {
    return substructure(object)?.filter {
        ($0["key.kind"] as? String).flatMap(SwiftDeclarationKind.init) == .VarInstance
    }.flatMap(RealmProperty.init) ?? []
}

public struct RealmObjectRule: Rule {
    public static let description = RuleDescription(
        identifier: "realm_object",
        name: "Realm Object",
        description: "Realm model objects should be defined according to " +
                     "https://realm.io/docs/swift/latest/#models.",
        nonTriggeringExamples: [
            // not subclassing RealmSwift.Object means this class is skipped
            "class Person: NSObject { var name: String = \"\" }",
            // no explicit type means this variable is skipped
            "class Person: Object { let name = \"\" }",
            // dynamic var String is legal
            "class Person: Object { dynamic var name: String = \"\" }",
            // dynamic var String? is legal
            "class Person: Object { dynamic var name: String? = nil }",
            // dynamic var Optional<String> is legal
            "class Person: Object { dynamic var name: Optional<String> = nil }",
            // let RealmOptional<Int> is legal
            "class Person: Object { let age: RealmOptional<Int> = 0 }",
        ],
        triggeringExamples: [
            // 'var' isn't marked as 'dynamic'
            "class Person: Object { var name: String = \"\" }",
            // 'String' type cannot be marked as 'let'
            "class Person: Object { let name: String = \"\" }",
            // 'let' cannot be marked as 'dynamic'
            "class Person: Object { dynamic let name: String = \"\" }",
            // 'Int' cannot be marked as 'Swift.Optional'
            "class Person: Object { dynamic var age: Optional<Int> = 0 }",
            // 'Int' cannot be marked as 'Swift.Optional'
            "class Person: Object { dynamic var age: Int? = 0 }",
            // 'String' cannot be marked as 'RealmOptional' (this wouldn't compile anyway)
            "class Person: Object { dynamic var name: RealmOptional<String> = nil }",
        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        return substructure(file.structure.dictionary)?.filter(isDictionaryRealmSubclass)
            .flatMap(propertiesForRealmObject).filter({ !$0.valid }).map {
                StyleViolation(ruleDescription: self.dynamicType.description,
                    location: Location(file: file, offset: $0.offset))
        } ?? []
    }
}
