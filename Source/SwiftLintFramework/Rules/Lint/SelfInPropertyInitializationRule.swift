import SourceKittenFramework

public struct SelfInPropertyInitializationRule: ConfigurationProviderRule, ASTRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "self_in_property_initialization",
        name: "Self in Property Initialization",
        description: "`self` refers to the unapplied `NSObject.self()` method, which is likely not expected. " +
            "Make the variable `lazy` to be able to refer to the current instance or use `ClassName.self`.",
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
            """),
            Example("""
            class View: UIView {
                private let collectionView: UICollectionView = {
                    let layout = UICollectionViewFlowLayout()
                    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
                    collectionView.registerReusable(Cell.self)

                    return collectionView
                }()
            }
            """),
            Example("""
            class Foo {
                var bar: Bool = false {
                    didSet {
                        value = {
                            if bar {
                                return self.calculateA()
                            } else {
                                return self.calculateB()
                            }
                        }()
                        print(value)
                    }
                }

                var value: String?

                func calculateA() -> String { "A" }
                func calculateB() -> String { "B" }
            }
            """, excludeFromDocumentation: true)
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
                guard let name = entry.name,
                      entry.expressionKind == .call, name.hasPrefix("{"),
                      let closureByteRange = entry.nameByteRange,
                      let closureRange = file.stringView.byteRangeToNSRange(closureByteRange) else {
                    return false
                }

                return file.match(pattern: "\\b(?<!\\.)self\\b", with: [.keyword], range: closureRange).isNotEmpty
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

                if let bodyRange = lastStructure.bodyByteRange,
                   bodyRange.contains(closureOffset) {
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
