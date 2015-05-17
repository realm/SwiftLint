//
//  Linter.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Foundation
import SwiftXPC
import SourceKittenFramework

public enum StyleViolationType: String, Printable {
    case NameFormat         = "Name Format"
    case Length             = "Length"
    case TrailingNewline    = "Trailing Newline"
    case LeadingWhitespace  = "Leading Whitespace"
    case TrailingWhitespace = "Trailing Whitespace"
    case ForceCast          = "Force Cast"

    public var description: String { return rawValue }
}

public struct Location: Printable, Equatable {
    public let file: String?
    public let line: Int?
    public let character: Int?
    public var description: String {
        // Xcode likes warnings and errors in the following format:
        // {full_path_to_file}{:line}{:character}: {error,warning}: {content}
        return (file ?? "<nopath>") +
            (map(line, { ":\($0)" }) ?? "") +
            (map(character, { ":\($0)" }) ?? "")
    }

    public init(file: String?, line: Int? = nil, character: Int? = nil) {
        self.file = file
        self.line = line
        self.character = character
    }

    public init(file: File, offset: Int) {
        self.file = file.path
        if let lineAndCharacter = file.contents.lineAndCharacterForByteOffset(offset) {
            line = lineAndCharacter.line
            character = nil // FIXME: Use lineAndCharacter.character once it works.
        } else {
            line = nil
            character = nil
        }
    }
}

// MARK: Equatable

/**
Returns true if `lhs` Location is equal to `rhs` Location.

:param: lhs Location to compare to `rhs`.
:param: rhs Location to compare to `lhs`.

:returns: True if `lhs` Location is equal to `rhs` Location.
*/
public func ==(lhs: Location, rhs: Location) -> Bool {
    return lhs.file == rhs.file &&
        lhs.line == rhs.line &&
        lhs.character == rhs.character
}

public enum ViolationSeverity: Int, Printable, Comparable {
    case VeryLow
    case Low
    case Medium
    case High
    case VeryHigh

    public var description: String {
        switch self {
            case .VeryLow:
                return "Very Low"
            case .Low:
                return "Low"
            case .Medium:
                return "Medium"
            case .High:
                return "High"
            case .VeryHigh:
                return "Very High"
        }
    }

    public var xcodeSeverityDescription: String {
        return self <= Medium ? "warning" : "error"
    }
}

// MARK: Comparable

public func == (lhs: ViolationSeverity, rhs: ViolationSeverity) -> Bool {
    return lhs.rawValue == rhs.rawValue
}
public func < (lhs: ViolationSeverity, rhs: ViolationSeverity) -> Bool {
    return lhs.rawValue < rhs.rawValue
}

public struct StyleViolation: Printable, Equatable {
    public let type: StyleViolationType
    public let severity: ViolationSeverity
    public let location: Location
    public let reason: String?
    public var description: String {
        // {full_path_to_file}{:line}{:character}: {error,warning}: {content}
        return "\(location): " +
            "\(severity.xcodeSeverityDescription): " +
            "\(type) Violation (\(severity) Severity): " +
            (reason ?? "")
    }

    public init(type: StyleViolationType, location: Location, reason: String? = nil) {
        severity = .Low
        self.type = type
        self.location = location
        self.reason = reason
    }
}

// MARK: Equatable

/**
Returns true if `lhs` StyleViolation is equal to `rhs` StyleViolation.

:param: lhs StyleViolation to compare to `rhs`.
:param: rhs StyleViolation to compare to `lhs`.

:returns: True if `lhs` StyleViolation is equal to `rhs` StyleViolation.
*/
public func ==(lhs: StyleViolation, rhs: StyleViolation) -> Bool {
    return lhs.type == rhs.type &&
        lhs.location == rhs.location &&
        lhs.reason == rhs.reason
}

typealias Line = (index: Int, content: String)

// Violation Extensions
extension File {
    func lineLengthViolations(lines: [Line]) -> [StyleViolation] {
        return lines.filter({ count($0.content) > 100 }).map {
            return StyleViolation(type: .Length,
                location: Location(file: self.path, line: $0.index),
                reason: "Line #\($0.index) should be 100 characters or less: " +
                "currently \(count($0.content)) characters")
        }
    }

    func leadingWhitespaceViolations(contents: String) -> [StyleViolation] {
        let countOfLeadingWhitespace = contents.countOfLeadingCharactersInSet(
            NSCharacterSet.whitespaceAndNewlineCharacterSet()
        )
        if countOfLeadingWhitespace != 0 {
            return [StyleViolation(type: .LeadingWhitespace,
                location: Location(file: self.path, line: 1),
                reason: "File shouldn't start with whitespace: " +
                "currently starts with \(countOfLeadingWhitespace) whitespace characters")]
        }
        return []
    }

    func forceCastViolations(file: File) -> [StyleViolation] {
        return flatMap(NSRegularExpression(pattern: "as!", options: nil, error: nil)) { regex in
            let range = NSRange(location: 0, length: count(file.contents.utf16))
            let syntax = SyntaxMap(file: file)
            let matches = regex.matchesInString(file.contents, options: nil, range: range)
            return map(matches as? [NSTextCheckingResult]) { matches in
                return compact(matches.map { match in
                    let offset = match.range.location
                    let tokenAtOffset = syntax.tokens.filter({ $0.offset == offset }).first
                    let syntaxKind = flatMap(tokenAtOffset?.type) { SyntaxKind(rawValue: $0) }
                    if syntaxKind != .Keyword {
                        return nil
                    }
                    return StyleViolation(type: .ForceCast,
                        location: Location(file: self, offset: offset),
                        reason: "Force casts should be avoided")
                })
            }
        } ?? []
    }

    func trailingLineWhitespaceViolations(lines: [Line]) -> [StyleViolation] {
        return lines.map { line in
            (
                index: line.index,
                trailingWhitespaceCount: line.content.countOfTailingCharactersInSet(
                    NSCharacterSet.whitespaceCharacterSet()
                )
            )
        }.filter {
            $0.trailingWhitespaceCount > 0
        }.map {
            StyleViolation(type: .TrailingWhitespace,
                location: Location(file: self.path, line: $0.index),
                reason: "Line #\($0.index) should have no trailing whitespace: " +
                "current has \($0.trailingWhitespaceCount) trailing whitespace characters")
        }
    }

    func trailingNewlineViolations(contents: String) -> [StyleViolation] {
        let countOfTrailingNewlines = contents.countOfTailingCharactersInSet(
            NSCharacterSet.newlineCharacterSet()
        )
        if countOfTrailingNewlines != 1 {
            return [StyleViolation(type: .TrailingNewline,
                location: Location(file: self.path),
                reason: "File should have a single trailing newline: " +
                "currently has \(countOfTrailingNewlines)")]
        }
        return []
    }

    func fileLengthViolations(lines: [Line]) -> [StyleViolation] {
        if lines.count > 400 {
            return [StyleViolation(type: .Length,
                location: Location(file: self.path),
                reason: "File should contain 400 lines or less: currently contains \(lines.count)")]
        }
        return []
    }

    func astViolationsInDictionary(dictionary: XPCDictionary) -> [StyleViolation] {
        return reduce((dictionary["key.substructure"] as? XPCArray ?? []).map {
            // swiftlint:disable_rule:force_cast (safe to force cast)
            let subDict = $0 as! XPCDictionary
            // swiftlint:enable_rule:force_cast
            var violations = self.astViolationsInDictionary(subDict)
            if let kindString = subDict["key.kind"] as? String,
                let kind = flatMap(kindString, { SwiftDeclarationKind(rawValue: $0) }) {
                violations.extend(self.validateTypeName(kind, dict: subDict))
                violations.extend(self.validateVariableName(kind, dict: subDict))
                violations.extend(self.validateTypeBodyLength(kind, dict: subDict))
                violations.extend(self.validateFunctionBodyLength(kind, dict: subDict))
            }
            return violations
        }, [], +)
    }

    func validateTypeBodyLength(kind: SwiftDeclarationKind, dict: XPCDictionary) ->
        [StyleViolation] {
            let typeKinds: [SwiftDeclarationKind] = [
                .Class,
                .Struct,
                .Enum
            ]
            if !contains(typeKinds, kind) {
                return []
            }
            var violations = [StyleViolation]()
            if let offset = flatMap(dict["key.offset"] as? Int64, { Int($0) }),
                let bodyOffset = flatMap(dict["key.bodyoffset"] as? Int64, { Int($0) }),
                let bodyLength = flatMap(dict["key.bodylength"] as? Int64, { Int($0) }) {
                let location = Location(file: self, offset: offset)
                let startLine = self.contents.lineAndCharacterForByteOffset(bodyOffset)
                let endLine = self.contents.lineAndCharacterForByteOffset(bodyOffset + bodyLength)
                if let startLine = startLine?.line, let endLine = endLine?.line
                    where endLine - startLine > 200 {
                    violations.append(StyleViolation(type: .Length,
                        location: location,
                        reason: "Type body should be span 200 lines or less: currently spans " +
                        "\(endLine - startLine) lines"))
                }
            }
            return violations
    }

    func validateFunctionBodyLength(kind: SwiftDeclarationKind, dict: XPCDictionary) ->
        [StyleViolation] {
        let functionKinds: [SwiftDeclarationKind] = [
            .FunctionAccessorAddress,
            .FunctionAccessorDidset,
            .FunctionAccessorGetter,
            .FunctionAccessorMutableaddress,
            .FunctionAccessorSetter,
            .FunctionAccessorWillset,
            .FunctionConstructor,
            .FunctionDestructor,
            .FunctionFree,
            .FunctionMethodClass,
            .FunctionMethodInstance,
            .FunctionMethodStatic,
            .FunctionOperator,
            .FunctionSubscript
        ]
        if !contains(functionKinds, kind) {
            return []
        }
        var violations = [StyleViolation]()
        if let offset = flatMap(dict["key.offset"] as? Int64, { Int($0) }),
            let bodyOffset = flatMap(dict["key.bodyoffset"] as? Int64, { Int($0) }),
            let bodyLength = flatMap(dict["key.bodylength"] as? Int64, { Int($0) }) {
            let location = Location(file: self, offset: offset)
            let startLine = self.contents.lineAndCharacterForByteOffset(bodyOffset)
            let endLine = self.contents.lineAndCharacterForByteOffset(bodyOffset + bodyLength)
            if let startLine = startLine?.line, let endLine = endLine?.line
                where endLine - startLine > 40 {
                violations.append(StyleViolation(type: .Length,
                    location: location,
                    reason: "Function body should be span 40 lines or less: currently spans " +
                    "\(endLine - startLine) lines"))
            }
        }
        return violations
    }

    func validateTypeName(kind: SwiftDeclarationKind, dict: XPCDictionary) -> [StyleViolation] {
        let typeKinds: [SwiftDeclarationKind] = [
            .Class,
            .Struct,
            .Typealias,
            .Enum,
            .Enumelement
        ]
        if !contains(typeKinds, kind) {
            return []
        }
        var violations = [StyleViolation]()
        if let name = dict["key.name"] as? String,
            let offset = flatMap(dict["key.offset"] as? Int64, { Int($0) }) {
            let location = Location(file: self, offset: offset)
            let nameCharacterSet = NSCharacterSet(charactersInString: name)
            if !NSCharacterSet.alphanumericCharacterSet().isSupersetOfSet(nameCharacterSet) {
                violations.append(StyleViolation(type: .NameFormat,
                    location: location,
                    reason: "Type name should only contain alphanumeric characters: '\(name)'"))
            } else if !name.substringToIndex(name.startIndex.successor()).isUppercase() {
                violations.append(StyleViolation(type: .NameFormat,
                    location: location,
                    reason: "Type name should start with an uppercase character: '\(name)'"))
            } else if count(name) < 3 || count(name) > 40 {
                violations.append(StyleViolation(type: .NameFormat,
                    location: location,
                    reason: "Type name should be between 3 and 40 characters in length: " +
                    "'\(name)'"))
            }
        }
        return violations
    }

    func validateVariableName(kind: SwiftDeclarationKind, dict: XPCDictionary) -> [StyleViolation] {
        let variableKinds: [SwiftDeclarationKind] = [
            .VarClass,
            .VarGlobal,
            .VarInstance,
            .VarLocal,
            .VarParameter,
            .VarStatic
        ]
        if !contains(variableKinds, kind) {
            return []
        }
        var violations = [StyleViolation]()
        if let name = dict["key.name"] as? String,
            let offset = flatMap(dict["key.offset"] as? Int64, { Int($0) }) {
            let location = Location(file: self, offset: offset)
            let nameCharacterSet = NSCharacterSet(charactersInString: name)
            if !NSCharacterSet.alphanumericCharacterSet().isSupersetOfSet(nameCharacterSet) {
                violations.append(StyleViolation(type: .NameFormat,
                    location: location,
                    reason: "Variable name should only contain alphanumeric characters: '\(name)'"))
            } else if name.substringToIndex(name.startIndex.successor()).isUppercase() {
                violations.append(StyleViolation(type: .NameFormat,
                    location: location,
                    reason: "Variable name should start with a lowercase character: '\(name)'"))
            } else if count(name) < 3 || count(name) > 40 {
                violations.append(StyleViolation(type: .NameFormat,
                    location: location,
                    reason: "Variable name should be between 3 and 40 characters in length: " +
                    "'\(name)'"))
            }
        }
        return violations
    }
}

extension String {
    func lines() -> [Line] {
        var lines = [Line]()
        var lineIndex = 1
        enumerateLines { line, stop in
            lines.append((lineIndex++, line))
        }
        return lines
    }

    func isUppercase() -> Bool {
        return self == uppercaseString
    }

    func countOfTailingCharactersInSet(characterSet: NSCharacterSet) -> Int {
        return String(reverse(self)).countOfLeadingCharactersInSet(characterSet)
    }
}

extension NSString {
    public func lineAndCharacterForByteOffset(offset: Int) -> (line: Int, character: Int)? {
        return flatMap(byteRangeToNSRange(start: offset, length: 0)) { range in
            var numberOfLines = 0
            var index = 0
            var lineRangeStart = 0
            while index < length {
                numberOfLines++
                if index <= range.location {
                    lineRangeStart = numberOfLines
                    index = NSMaxRange(self.lineRangeForRange(NSRange(location: index, length: 1)))
                } else {
                    break
                }
            }
            return (lineRangeStart, 0)
        }
    }
}

public struct Linter {
    private let file: File
    private let structure: Structure

    public var styleViolations: [StyleViolation] {
        return file.astViolationsInDictionary(structure.dictionary) + stringViolations
    }

    private var stringViolations: [StyleViolation] {
        let lines = file.contents.lines()
        // FIXME: Using '+' to concatenate these arrays would be nicer,
        //        but slows the compiler to a crawl.
        var violations = file.lineLengthViolations(lines)
        violations.extend(file.leadingWhitespaceViolations(file.contents))
        violations.extend(file.trailingLineWhitespaceViolations(lines))
        violations.extend(file.trailingNewlineViolations(file.contents))
        violations.extend(file.forceCastViolations(file))
        violations.extend(file.fileLengthViolations(lines))
        return violations
    }

    /**
    Initialize a Linter by passing in a File.

    :param: file File to lint.
    */
    public init(file: File) {
        self.file = file
        structure = Structure(file: file)
    }
}
