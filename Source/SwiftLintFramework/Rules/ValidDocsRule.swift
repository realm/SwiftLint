//
//  ValidDocsRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-11-21.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

extension File {
    private func invalidDocOffsets(dictionary: [String: SourceKitRepresentable]) -> [Int] {
        let substructure = (dictionary["key.substructure"] as? [SourceKitRepresentable])?
            .flatMap { $0 as? [String: SourceKitRepresentable] } ?? []
        let substructureOffsets = substructure.flatMap(invalidDocOffsets)
        guard let kind = (dictionary["key.kind"] as? String).flatMap(SwiftDeclarationKind.init)
            where kind != .VarParameter,
            let offset = dictionary["key.offset"] as? Int64,
            bodyOffset = dictionary["key.bodyoffset"] as? Int64,
            comment = getDocumentationCommentBody(dictionary, syntaxMap: syntaxMap)
            where !comment.containsString(":nodoc:") else {
                return substructureOffsets
        }
        let declaration = (contents as NSString)
            .substringWithByteRange(start: Int(offset), length: Int(bodyOffset - offset))!
        let hasViolation = missingReturnDocumentation(declaration, comment: comment) ||
            superfluousReturnDocumentation(declaration, comment: comment, kind: kind) ||
            superfluousOrMissingThrowsDocumentation(declaration, comment: comment) ||
            superfluousOrMissingParameterDocumentation(declaration, substructure: substructure,
                                                       offset: offset, bodyOffset: bodyOffset,
                                                       comment: comment)

        return substructureOffsets + (hasViolation ? [Int(offset)] : [])
    }
}

func superfluousOrMissingThrowsDocumentation(declaration: String, comment: String) -> Bool {
    guard let outsideBracesMatch = matchOutsideBraces(declaration) else {
        return false == !comment.lowercaseString.containsString("- throws:")
    }
    return outsideBracesMatch.containsString(" throws ") ==
        !comment.lowercaseString.containsString("- throws:")
}

func declarationReturns(declaration: String, kind: SwiftDeclarationKind? = nil) -> Bool {
    if let kind = kind where SwiftDeclarationKind.variableKinds().contains(kind) {
        return true
    }

    guard let outsideBracesMatch = matchOutsideBraces(declaration) else {
        return false
    }
    return outsideBracesMatch.containsString("->")
}

func matchOutsideBraces(declaration: String) -> NSString? {
    guard let outsideBracesMatch =
        regex("(?:\\)(\\s*\\w*\\s*)*((\\s*->\\s*)(\\(.*\\))*(?!.*->)[^()]*(\\(.*\\))*)?\\s*\\{)")
        .matchesInString(declaration, options: [],
            range: NSRange(location: 0, length: declaration.characters.count)).first else {
                return nil
    }

    return NSString(string: declaration).substringWithRange(outsideBracesMatch.range)
}

func declarationIsInitializer(declaration: String) -> Bool {
    return !regex("^((.+)?\\s+)?init\\?*\\(.*\\)")
        .matchesInString(declaration, options: [],
                         range: NSRange(location: 0, length: declaration.characters.count)).isEmpty
}

func commentHasBatchedParameters(comment: String) -> Bool {
    return comment.lowercaseString.containsString("- parameters:")
}

func commentReturns(comment: String) -> Bool {
    return comment.lowercaseString.containsString("- returns:") ||
        comment.rangeOfString("Returns")?.startIndex == comment.startIndex
}

func missingReturnDocumentation(declaration: String, comment: String) -> Bool {
    guard !declarationIsInitializer(declaration) else {
        return false
    }
    return declarationReturns(declaration) && !commentReturns(comment)
}

func superfluousReturnDocumentation(declaration: String, comment: String,
                                    kind: SwiftDeclarationKind) -> Bool {
    guard !declarationIsInitializer(declaration) else {
        return false
    }
    return !declarationReturns(declaration, kind: kind) && commentReturns(comment)
}

func superfluousOrMissingParameterDocumentation(declaration: String,
                                                substructure: [[String: SourceKitRepresentable]],
                                                offset: Int64, bodyOffset: Int64,
                                                comment: String) -> Bool {
    // This function doesn't handle batched parameters, so skip those.
    if commentHasBatchedParameters(comment) { return false }
    let parameterNames = substructure.filter {
        ($0["key.kind"] as? String).flatMap(SwiftDeclarationKind.init) == .VarParameter
    }.filter { subDict in
        return (subDict["key.offset"] as? Int64).map({ $0 < bodyOffset }) ?? false
    }.flatMap {
        $0["key.name"] as? String
    } ?? []
    let labelsAndParams = parameterNames.map { parameter -> (label: String, parameter: String) in
        let fullRange = NSRange(location: 0, length: declaration.utf16.count)
        let firstMatch = regex("([^,\\s(]+)\\s+\(parameter)\\s*:")
            .firstMatchInString(declaration, options: [], range: fullRange)
        if let match = firstMatch {
            let label = (declaration as NSString).substringWithRange(match.rangeAtIndex(1))
            return (label, parameter)
        }
        return (parameter, parameter)
    }
    let optionallyDocumentedParameterCount = labelsAndParams.filter({ $0.0 == "_" }).count
    let commentRange = NSRange(location: 0, length: comment.utf16.count)
    let commentParameterMatches = regex("- [p|P]arameter ([^:]+)")
        .matchesInString(comment, options: [], range: commentRange)
    let commentParameters = commentParameterMatches.map { match in
        return (comment as NSString).substringWithRange(match.rangeAtIndex(1))
    }
    if commentParameters.count > labelsAndParams.count ||
        labelsAndParams.count - commentParameters.count > optionallyDocumentedParameterCount {
        return true
    }
    return !zip(commentParameters, labelsAndParams).filter {
        ![$1.label, $1.parameter].contains($0)
    }.isEmpty
}

public struct ValidDocsRule: ConfigurationProviderRule {

    public var configuration = SeverityConfiguration(.Warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "valid_docs",
        name: "Valid Docs",
        description: "Documented declarations should be valid.",
        nonTriggeringExamples: [
            "/// docs\npublic func a() {}\n",
            "/// docs\n/// - parameter param: this is void\npublic func a(param: Void) {}\n",
            "/// docs\n/// - parameter label: this is void\npublic func a(label param: Void) {}",
            "/// docs\n/// - parameter param: this is void\npublic func a(label param: Void) {}",
            "/// docs\n/// - Parameter param: this is void\npublic func a(label param: Void) {}",
            "/// docs\n/// - returns: false\npublic func no() -> Bool { return false }",
            "/// docs\n/// - Returns: false\npublic func no() -> Bool { return false }",
            "/// Returns false\npublic func no() -> Bool { return false }",
            "/// Returns false\nvar no: Bool { return false }",
            "/// docs\nvar no: Bool { return false }",
            "/// docs\n/// - throws: NSError\nfunc a() throws {}",
            "/// docs\n/// - Throws: NSError\nfunc a() throws {}",
            "/// docs\n/// - parameter param: this is void\n/// - returns: false" +
                "\npublic func no(param: (Void -> Void)?) -> Bool { return false }",
            "/// docs\n/// - parameter param: this is void" +
                "\n///- parameter param2: this is void too\n/// - returns: false",
            "\npublic func no(param: (Void -> Void)?, param2: String->Void) -> Bool " +
                "{return false}",
            "/// docs\n/// - parameter param: this is void" +
                "\npublic func no(param: (Void -> Void)?) {}",
            "/// docs\n/// - parameter param: this is void" +
                "\n///- parameter param2: this is void too" +
                "\npublic func no(param: (Void -> Void)?, param2: String->Void) {}",
            "/// docs👨‍👩‍👧‍👧\n/// - returns: false\npublic func no() -> Bool { return false }",
            "/// docs\n/// - returns: tuple\npublic func no() -> (Int, Int) {return (1, 2)}",
            "/// docs\n/// - returns: closure\npublic func no() -> (Void->Void) {}",
            "/// docs\n/// - parameter param: this is void" +
                "\n/// - parameter param2: this is void too" +
                "\nfunc no(param: (Void) -> Void, onError param2: ((NSError) -> Void)? = nil) {}",
            "/// docs\n/// - parameter param: this is a void closure" +
                "\n/// - parameter param2: this is a void closure too" +
                "\n/// - parameter param3: this is a void closure too" +
                "\nfunc a(param: () -> Void, param2: (parameter: Int) -> Void, " +
                "param3: (parameter: Int) -> Void) {}",
            "/// docs\n/// - parameter param: this is a void closure" +
                "\n/// - Parameter param2: this is a void closure too" +
                "\n/// - Parameter param3: this is a void closure too" +
                "\nfunc a(param: () -> Void, param2: (parameter: Int) -> Void, " +
                "param3: (parameter: Int) -> Void) {}",
            "/// docs\n/// - parameter param: this is a void closure" +
                "\n/// - returns: Foo<Void>" +
                "\nfunc a(param: () -> Void) -> Foo<Void> {return Foo<Void>}",
            "/// docs\n/// - parameter param: this is a void closure" +
                "\n/// - returns: Foo<Void>" +
                "\nfunc a(param: () -> Void) -> Foo<[Int]> {return Foo<[Int]>}",
            "/// docs\n/// - throws: NSError\n/// - returns: false" +
                "\nfunc a() throws -> Bool { return true }",
            "/// docs\n/// - parameter param: this is a closure\n/// - returns: Bool" +
                "\nfunc a(param: (Void throws -> Bool)) -> Bool { return true }",
        ],
        triggeringExamples: [
            "/// docs\npublic ↓func a(param: Void) {}\n",
            "/// docs\n/// - parameter invalid: this is void\npublic ↓func a(param: Void) {}",
            "/// docs\n/// - parameter invalid: this is void\npublic ↓func a(label param: Void) {}",
            "/// docs\n/// - parameter invalid: this is void\npublic ↓func a() {}",
            "/// docs\npublic ↓func no() -> Bool { return false }",
            "/// Returns false\npublic ↓func a() {}",
            "/// docs\n/// - throws: NSError\n↓func a() {}",
            "/// docs\n↓func a() throws {}",
            "/// docs\n/// - parameter param: this is void" +
                "\npublic ↓func no(param: (Void -> Void)?) -> Bool { return false }",
            "/// docs\n/// - parameter param: this is void" +
                "\n///- parameter param2: this is void too" +
                "\npublic ↓func no(param: (Void -> Void)?, param2: String->Void) -> " +
                "Bool {return false}",
            "/// docs\n/// - parameter param: this is void\n/// - returns: false" +
                "\npublic ↓func no(param: (Void -> Void)?) {}",
            "/// docs\n/// - parameter param: this is void" +
                "\n///- parameter param2: this is void too\n/// - returns: false" +
                "\npublic ↓func no(param: (Void -> Void)?, param2: String->Void) {}",
            "/// docs\npublic func no() -> (Int, Int) {return (1, 2)}",
            "/// docs\n/// - parameter param: this is void" +
                "\n///- parameter param2: this is void too\n///- returns: closure" +
                "\nfunc no(param: (Void) -> Void, onError param2: ((NSError) -> Void)? = nil) {}",
            "/// docs\n/// - parameter param: this is a void closure" +
                "\nfunc a(param: () -> Void) -> Foo<Void> {return Foo<Void>}",
            "/// docs\n/// - parameter param: this is a void closure" +
                "\nfunc a(param: () -> Void) -> Foo<[Int]> {return Foo<[Int]>}",
            "/// docs\nfunc a() throws -> Bool { return true }",
        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        return file.invalidDocOffsets(file.structure.dictionary).map {
            StyleViolation(ruleDescription: self.dynamicType.description,
                severity: configuration.severity,
                location: Location(file: file, byteOffset: $0))
        }
    }
}
