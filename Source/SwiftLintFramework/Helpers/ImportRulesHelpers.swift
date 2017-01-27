//
//  ImportRulesHelpers.swift
//  SwiftLint
//
//  Created by Miguel Revetria on 8/2/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

// MARK: - ImportKind

internal enum ImportKind: String {

    case `class­`
    case `default` = ""
    case `enum`
    case `func`
    case `protocol`
    case `struct`
    case `typealias`
    case `var`

    init(importContent content: String) {
        let content = content
            .replacingOccurrences(of: "@testable", with: "")

        self = ImportKind.all()
            .first { kind in
                guard !kind.rawValue.isEmpty else {
                    return false
                }
                return content.hasPrefix("import \(kind.rawValue)")
            } ?? .default
    }

    static func all() -> [ImportKind] {
        return [
            .class­,
            .default,
            .enum,
            .func,
            .protocol,
            .struct,
            .typealias,
            .var
        ]
    }

}

internal func == (lhs: ImportKind, rhs: ImportKind) -> Bool {
    return lhs.rawValue == rhs.rawValue
}

// MARK: - ImportKind

internal struct Import: Equatable {

    let kind: ImportKind
    let range: NSRange
    let byteRange: NSRange
    let offset: Int
    let content: String
    let module: String
    let isTestable: Bool

    func isLessThan(_ other: Import, ignoringCase: Bool = false) -> Bool {
        if isTestable != other.isTestable { return !isTestable }
        if kind != other.kind { return kind.rawValue < other.kind.rawValue }
        if ignoringCase {
            return module < other.module
        } else {
            return module.lowercased() < other.module.lowercased()
        }
    }

}

internal func == (lhs: Import, rhs: Import) -> Bool {
    return lhs.content == rhs.content
}

// MARK: - File extensions

internal extension File {

    internal func parseImports() -> [Import] {
        let contents = self.contents.bridge()

        let kindPattern: String = ImportKind.all().map { $0.rawValue }.filter { !$0.isEmpty }.joined(separator: "|")
        let importRanges: [(range: NSRange, byteRange: NSRange)] =
            match(pattern: "(@testable\\s+)?import\\s+((\(kindPattern))\\s+)?\\w+(\\.\\w+)*")
                .flatMap { range, syntaxKinds in
                    guard validSyntaxKinds(syntaxKinds: syntaxKinds) else {
                        return nil
                    }
                    return (
                        range: range,
                        byteRange: contents.NSRangeToByteRange(start: range.location, length: range.length) ?? range
                    )
                }

        return importRanges.flatMap { range, byteRange in
            let content = contents.substring(with: range)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let moduleName = content.replacingOccurrences(
                of: "(@testable\\s+)?import\\s+((\(kindPattern))\\s+)?",
                with: "",
                options: String.CompareOptions.regularExpression
            )

            return Import(
                kind: ImportKind(importContent: content),
                range: range,
                byteRange: byteRange,
                offset: NSMaxRange(range) - moduleName.bridge().length,
                content: content,
                module: moduleName,
                isTestable: content.hasPrefix("@testable")
            )
        }
    }

    fileprivate func validSyntaxKinds(syntaxKinds: [SyntaxKind]) -> Bool {
        guard !syntaxKinds.isEmpty else {
            return false
        }
        var reduced = syntaxKinds

        if reduced[0] == SyntaxKind.keyword {
            reduced.insert(SyntaxKind.attributeBuiltin, at: 0)
        }

        guard reduced.count >= 3 else {
            return false
        }

        if reduced[1] == SyntaxKind.keyword && reduced[2] == SyntaxKind.keyword {
            reduced.remove(at: 2)
        }
        if reduced.count >= 3 && reduced[2] == SyntaxKind.identifier {
            var ind = 3
            while ind < reduced.count {
                guard reduced[ind] == SyntaxKind.identifier else {
                    ind += 1
                    break
                }
                reduced.remove(at: ind)
            }
        }

        let validPattern: [SyntaxKind] = [.attributeBuiltin, .keyword, .identifier]
        return validPattern == reduced
    }

}
