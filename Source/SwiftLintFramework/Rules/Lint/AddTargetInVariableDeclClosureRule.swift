import SourceKittenFramework

public struct AddTargetInVariableDeclClosureRule: ConfigurationProviderRule, ASTRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "add_target_in_variable_declaration_closure",
        name: "Add Target in Variable Declaration Closure",
        description: "When using addTarget(_:, action:, for:) inside an inline closure used " +
            "for initializing a variable, self won't have the proper value. Make the variable lazy to fix it.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
            class View: UIView {
                let button: UIButton = {
                    return UIButton()
                }()
            }
            """),
            Example("""
            class View: UIView {
                lazy var button: UIButton = {
                    let button = UIButton()
                    button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
                    return button
                }()
            }
            """),
            Example("""
            class View: UIView {
                var button: UIButton = {
                    let button = UIButton()
                    button.addTarget(otherObject, action: #selector(didTapButton), for: .touchUpInside)
                    return button
                }()
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            class View: UIView {
                ↓var button: UIButton = {
                    let button = UIButton()
                    button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
                    return button
                }()
            }
            """),
            Example("""
            class View: UIView {
                ↓let button: UIButton = {
                    let button = UIButton()
                    button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
                    return button
                }()
            }
            """)
        ]
    )

    public func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard kind == .class else {
            return []
        }

        let inlineClosures = dictionary.substructure
            .filter { entry in
                guard let name = entry.name else {
                    return false
                }
                return entry.expressionKind == .call && name.hasPrefix("{")
            }
            .filter { entry in
                !entry.traverseBreadthFirst { dict -> [SourceKittenDictionary] in
                    guard dict.expressionKind == .call, let name = dict.name,
                          name.hasSuffix(".addTarget"),
                          dict.enclosedArguments.map(\.name) == [nil, "action", "for"],
                          let firstParamBodyRange = dict.enclosedArguments[0].bodyByteRange,
                          file.stringView.substringWithByteRange(firstParamBodyRange) == "self",
                          file.syntaxMap.kinds(inByteRange: firstParamBodyRange) == [.keyword] else {
                        return []
                    }

                    return [dict]
                }.isEmpty
            }

        let variableDeclarations = inlineClosures.compactMap { closureDict -> ByteCount? in
            guard let closureOffset = closureDict.offset else {
                return nil
            }

            let lastStructure = dictionary.substructure.last { dict in
                guard let offset = dict.offset else {
                    return false
                }
                return offset < closureOffset
            }

            return lastStructure.flatMap { lastStructure -> ByteCount? in
                guard lastStructure.declarationKind == .varInstance,
                      !lastStructure.enclosedSwiftAttributes.contains(.lazy) else {
                    return nil
                }

                return lastStructure.offset
            }
        }

        return variableDeclarations.map { byteOffset in
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: byteOffset))
        }
    }
}
