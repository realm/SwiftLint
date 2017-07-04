//
//  ModifiersOrderRule.swift
//  SwiftLint
//
//  Created by Jose Cheyo Jimenez on 05/06/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

private extension Array where Element == String {
    func sorted(byComparingTo reference: [String]) -> [String] {
        return self.sorted(by: { (lhs, rhs) -> Bool in
            guard let left = reference.index(of: lhs), let right = reference.index(of: rhs)
                else { return false }
            return left < right
        })
    }
}

public struct ModifiersOrderRule: OptInRule, ConfigurationProviderRule {
    public init() { }
    public var configuration = ModifiersOrderConfiguration(beforeACL: ["override"], afterACL: [])
    public static let description = RuleDescription(
        identifier: "modifiers_order",
        name: "Modifiers Order",
        description: "Modifiers order should be consistent.", kind: RuleKind.style,
        nonTriggeringExamples: [
            "@objc \npublic final class MyClass: NSObject {\n" +
            "private final func myFinal() {}\n" +
            "weak var myWeak: NSString? = nil\n" +
            "public static let nnumber = 3 \n }",

            "public final class MyClass {}"
        ],
        triggeringExamples: [
            "@objc \npublic final class MyClass: NSObject {\n" +
            "final private func myFinal() {}\n}",

            "@objc \nfinal public class MyClass: NSObject {}\n",

            "final public class MyClass {}\n",

            "class MyClass {" +
            "weak internal var myWeak: NSString? = nil\n}",

            "class MyClass {" +
            "static public let nnumber = 3 \n }"
        ]
    )

    private func extractContinuousSections(from tokens: [SyntaxToken], in file: File) -> [[SyntaxToken]] {
        var builtInTokenSections = [[SyntaxToken]]()
        var tokenSection = [SyntaxToken]()
        let builtIn = "source.lang.swift.syntaxtype.attribute.builtin"
        let keyword = "source.lang.swift.syntaxtype.keyword"
        let declClass = "source.lang.swift.decl.class"

        for token in tokens {
            // static & class are not builtin attibutes so we check every keyword for static || class
            if token.type == keyword,
                token.length == "static".bridge().length || token.length == "class".bridge().length,
                let keywordAtLoc = file.contents.bridge()
                                .substringWithByteRange(start: token.offset, length: token.length) {
                    switch keywordAtLoc {
                    case "static":
                        tokenSection.append(token)
                    // filter out `class` when used as a declaration
                    case "class" :
                        if let (kind, _) = file.structure.kinds(forByteOffset: token.offset)
                                            .first(where: { $0.byteRange.location == token.offset }),
                            kind != declClass {
                                tokenSection.append(token)
                            }
                    default: continue
                    }
            } else if token.type == builtIn {
                tokenSection.append(token)
            } else if !tokenSection.isEmpty {
                builtInTokenSections.append(tokenSection)
                tokenSection.removeAll()
            }
        }
        if !tokenSection.isEmpty {
            builtInTokenSections.append(tokenSection)
        }
        return builtInTokenSections.filter({ $0.count > 1 })
    }

    private func isAccessControlLabel(_ input: String) -> Bool {
        let ACL = ["private", "internal", "public", "open"]
        // were are checking the prefix so we dont need fileprivate, private(set), public(set), ETC
        for each in ACL where input.hasPrefix(each) {
            return true
        }
        return false
    }

    public func validate(file: File) -> [StyleViolation] {
        let tokenSections = extractContinuousSections(from: file.syntaxMap.tokens, in: file)
        let builtIns: [(offset: Int, values: [String])] = tokenSections.flatMap({
            guard let first = $0.first, let last = $0.last
                else { return nil }
            let length = last.offset - first.offset + last.length
            guard let builtInString = file.contents.bridge().substringWithByteRange(start: first.offset, length: length)
                else { return nil }
            let strings = builtInString.bridge().components(separatedBy: CharacterSet.whitespacesAndNewlines)
                    .filter({ !$0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty })
            return (first.offset, strings)
        })
        return builtIns.flatMap({
            var attibutes = [String]()
            var accessLabels = [String]()
            var beforeACL = [String]()
            var afterACL = [String]()
            var otherModifiers = [String]()

            for each in $0.values {
                if each.hasPrefix("@") {
                    attibutes.append(each)
                    continue
                }
                if isAccessControlLabel(each) {
                    accessLabels.append(each)
                    continue
                }
                // The same element is not in both beforeACL & afterACL
                // The config file checks this and if not it throws an invalid config error
                if configuration.beforeACL.contains(each) {
                    beforeACL.append(each)
                    continue
                }
                if configuration.afterACL.contains(each) {
                    afterACL.append(each)
                    continue
                }
                // Catch All for non configured modifiers
                otherModifiers.append(each)

            }
            // sorting according to  reference configuration
            beforeACL = beforeACL.sorted(byComparingTo: configuration.beforeACL)
            afterACL = afterACL.sorted(byComparingTo: configuration.afterACL)

            let ordered = attibutes + beforeACL + accessLabels + afterACL + otherModifiers
            if ordered == $0.values {
                return nil
            } else {
             return StyleViolation(ruleDescription: ModifiersOrderRule.description,
                                   location: Location(file: file, byteOffset: $0.offset),
                                   reason: ordered.joined(separator: " "))
            }
        })
    }
}
