//
//  FileprivateRule.swift
//  SwiftLint
//
//  Created by Jose Cheyo Jimenez on 05/02/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct FileprivateRule: Rule, ConfigurationProviderRule {
    public var configuration = FileprivateConfiguration(strict: false)

    public init() {}

    public static let description = FileprivateConfiguration.fileprivateLimited

    public func validate(file: File) -> [StyleViolation] {
        if !configuration.strict {
            let toplevel = file.structure.dictionary.substructure.flatMap({ $0.offset })
            let syntaxTokens = file.syntaxMap.tokens
            let violationOffsets = toplevel.flatMap { (offSet) -> Int? in
                let parts = syntaxTokens.partitioned { offSet <= $0.offset }
                guard let lastKind = parts.first.last,
                    lastKind.type == SyntaxKind.attributeBuiltin.rawValue,
                    // Cut the amount of name-look-ups by first checking the char count
                    lastKind.length == "fileprivate".bridge().length,
                    // Get the actual name of the attibute
                    let aclName = file.contents.bridge()
                            .substringWithByteRange(start:lastKind.offset, length: lastKind.length),
                    // fileprivate(set) is not possible at toplevel
                    aclName == "fileprivate"
                    else { return nil }
                return offSet
            }
            return violationOffsets.map({ StyleViolation(
                ruleDescription: FileprivateConfiguration.fileprivateLimited,
                location: Location(file: file, byteOffset: $0))
            })

        } else { // Mark all fileprivate occurences as a violation
            let fileprivates = file.match(pattern: "fileprivate", with: [.attributeBuiltin]).flatMap({
                file.contents.bridge().NSRangeToByteRange(start: $0.location, length: $0.length)
            }).map({ $0.location })
            return fileprivates.map({ StyleViolation(
                ruleDescription: FileprivateConfiguration.fileprivateDisallowed,
                location: Location(file: file, byteOffset: $0))
            })
        }

    }
}
