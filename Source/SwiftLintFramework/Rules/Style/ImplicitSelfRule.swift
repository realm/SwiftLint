import Foundation
import SourceKittenFramework

public struct ImplicitSelfRule: OptInRule, ConfigurationProviderRule {
    public var configuration = ImplicitSelfConfiguration(severity: .warning, initSelfUsage: .never)

    public init() {}

    public static let description = RuleDescription(
        identifier: "implicit_self",
        name: "Implicit Self",
        description: "Instance variables and methods should not be accessed with 'self.' unless necessary.",
        kind: .style
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let identifiers = file.syntaxMap.tokens.compactMap { token -> Identifier? in
            guard let kind = token.kind, kind == .identifier else { return nil }

            return Identifier(token: token, file: file)
        }

        let structure = Structure(dict: file.structureDictionary.value)

        for identifier in identifiers {
            structure.add(identifier: identifier)
        }

        return violations(in: structure, declInScope: [], file: file)
    }

    private func violations(in structure: Structure,
                            declInScope: Set<String>,
                            file: SwiftLintFile) -> [StyleViolation] {
        var existingDeclInScope: Set<String> = declInScope
        guard !structure.isClosure else { return [] }
        if structure.isInit && configuration.initSelfUsage == .always { return [] }
        let violations = structure.identifiers.compactMap { identifier -> StyleViolation? in
            guard identifier.name != "init" else { return nil }

            guard !identifier.isParamDecl && !identifier.isLocalDecl else {
                existingDeclInScope.insert(identifier.name)
                return nil
            }

            if configuration.initSelfUsage == .beforeInitCall &&
                structure.isInit &&
                structure.hasInitBefore(identifier: identifier) {
                return nil
            }

            let selfOffset = identifier.offset - 5
            guard file.stringView.substringWithByteRange(ByteRange(location: selfOffset, length: 5)) == "self." else {
                return nil
            }

            guard !existingDeclInScope.contains(identifier.name) else { return nil }

            guard let range = file.stringView.byteRangeToNSRange(
                ByteRange(location: selfOffset, length: 0)
            ) else { return nil }

            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: configuration.severity.severity,
                                  location: Location(file: file, characterOffset: range.location))
        }

        let subViolations = structure.substructure.flatMap { substructure -> [StyleViolation] in
            if configuration.initSelfUsage == .beforeInitCall &&
                structure.isInit &&
                structure.hasInitBefore(structure: substructure) {
                return []
            }

            return self.violations(in: substructure, declInScope: existingDeclInScope, file: file)
        }

        return violations + subViolations
    }
}

private struct Identifier {
    let name: String
    let kind: String
    let offset: ByteCount

    init?(token: SwiftLintSyntaxToken, file: SwiftLintFile) {
        name = file.stringView.substringWithByteRange(ByteRange(location: token.offset, length: token.length)) ?? ""
        kind = token.kind?.rawValue ?? ""
        offset = token.offset
    }

    init(name: String, kind: String, offset: Int64) {
        self.name = name
        self.kind = kind
        self.offset = ByteCount(offset)
    }

    var isLocalDecl: Bool {
        return kind == "source.lang.swift.decl.var.local" ||
            kind == "source.lang.swift.decl.function.method.local"
    }

    var isParamDecl: Bool {
        return kind == "source.lang.swift.decl.var.parameter" ||
            kind == "source.lang.swift.decl.function.method.parameter"
    }
}

private class Structure {
    let offset: Int64?
    let bodyoffset: Int64?
    let length: Int64?
    let bodylength: Int64?
    let kind: String?
    let name: String?
    let substructure: [Structure]

    var identifiers: [Identifier] = []

    var hasBody: Bool {
        return bodyoffset != nil && bodylength != nil && (bodylength ?? 0) > 0
    }

    var isLocalDecl: Bool {
        return kind == "source.lang.swift.decl.var.local" ||
            kind == "source.lang.swift.decl.function.method.local"
    }

    var isParamDecl: Bool {
        return kind == "source.lang.swift.decl.var.parameter" ||
            kind == "source.lang.swift.decl.function.method.parameter"
    }

    var isClosure: Bool {
        return kind == "source.lang.swift.expr.closure"
    }

    var isTuple: Bool {
        return kind == "source.lang.swift.expr.tuple"
    }

    var isInit: Bool {
        return kind == "source.lang.swift.decl.function.method.instance" &&
            name?.starts(with: "init") ?? false
    }

    private var enclosedParameters: [Identifier] {
        return substructure.flatMap { structure -> [Identifier] in
            if structure.isParamDecl {
                return [
                    Identifier(name: structure.name ?? "",
                               kind: structure.kind ?? "",
                               offset: structure.offset ?? 0)
                ]
            }

            return []
        }
    }

    private var enclosedLocalVars: [Identifier] {
        return substructure.flatMap { structure -> [Identifier] in
            if structure.isLocalDecl {
                return [
                    Identifier(name: structure.name ?? "",
                               kind: structure.kind ?? "",
                               offset: structure.offset ?? 0)
                ]
            }

            if !structure.hasBody || structure.isTuple {
                return structure.enclosedLocalVars
            }

            return []
        }
    }

    init(dict: [String: SourceKitRepresentable]) {
        offset = dict["key.offset"] as? Int64
        bodyoffset = dict["key.bodyoffset"] as? Int64
        length = dict["key.length"] as? Int64
        bodylength = dict["key.bodylength"] as? Int64
        kind = dict["key.kind"] as? String
        name = dict["key.name"] as? String
        if let substructure = dict["key.substructure"] as? [[String: SourceKitRepresentable]] {
            self.substructure = substructure.map(Structure.init)
        } else {
            substructure = []
        }

        // add parameters
        identifiers.append(contentsOf: enclosedParameters)

        // add local vars
        identifiers.append(contentsOf: enclosedLocalVars)
    }

    @discardableResult
    func add(identifier: Identifier) -> Bool {
        for sub in substructure {
            if sub.add(identifier: identifier) {
                return true
            }
        }

        if let offset = offset,
            let length = length,
            hasBody,
            identifier.offset.value >= offset,
            identifier.offset.value < offset + length {
            let index = identifiers.firstIndex(where: {
                $0.offset.value > identifier.offset.value
            }) ?? identifiers.endIndex
            identifiers.insert(identifier, at: index)

            return true
        }

        return false
    }

    func hasInitBefore(identifier: Identifier) -> Bool {
        return !identifiers.contains(where: { $0.offset < identifier.offset && $0.name == "init" })
    }

    func hasInitBefore(structure: Structure) -> Bool {
        return !identifiers.contains(where: { $0.offset.value < (structure.offset ?? 0) && $0.name == "init" })
    }
}
