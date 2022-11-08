import SourceKittenFramework

struct CaptureVariableRule: ConfigurationProviderRule, AnalyzerRule, CollectingRule {
    struct Variable: Hashable {
        let usr: String
        let offset: ByteCount
    }

    typealias USR = String
    typealias FileInfo = Set<USR>

    static let description = RuleDescription(
        identifier: "capture_variable",
        name: "Capture Variable",
        description: "Non-constant variables should not be listed in a closure's capture list" +
            " to avoid confusion about closures capturing variables at creation time.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
            class C {
                let i: Int
                init(_ i: Int) { self.i = i }
            }

            let j: Int = 0
            let c = C(1)

            let closure: () -> Void = { [j, c] in
                print(c.i, j)
            }

            closure()
            """),
            Example("""
            let iGlobal: Int = 0

            class C {
                class var iClass: Int { 0 }
                static let iStatic: Int = 0
                let iInstance: Int = 0

                func callTest() {
                    var iLocal: Int = 0
                    test { [unowned self, iGlobal, iInstance, iLocal, iClass=C.iClass, iStatic=C.iStatic] j in
                        print(iGlobal, iClass, iStatic, iInstance, iLocal, j)
                    }
                }

                func test(_ completionHandler: @escaping (Int) -> Void) {
                }
            }
            """),
            Example("""
            var j: Int!
            j = 0

            let closure: () -> Void = { [j] in
                print(j)
            }

            closure()
            j = 1
            closure()
            """),
            Example("""
            lazy var j: Int = { 0 }()

            let closure: () -> Void = { [j] in
                print(j)
            }

            closure()
            j = 1
            closure()
            """)
        ],
        triggeringExamples: [
            Example("""
            var j: Int = 0

            let closure: () -> Void = { [j] in
                print(j)
            }

            closure()
            j = 1
            closure()
            """),
            Example("""
            class C {
                let i: Int
                init(_ i: Int) { self.i = i }
            }

            var c = C(0)
            let closure: () -> Void = { [c] in
                print(c.i)
            }

            closure()
            c = C(1)
            closure()
            """),
            Example("""
            var iGlobal: Int = 0

            class C {
                func callTest() {
                    test { [iGlobal] j in
                        print(iGlobal, j)
                    }
                }

                func test(_ completionHandler: @escaping (Int) -> Void) {
                }
            }
            """),
            Example("""
            class C {
                static var iStatic: Int = 0

                static func callTest() {
                    test { [↓iStatic] j in
                        print(iStatic, j)
                    }
                }

                static func test(_ completionHandler: @escaping (Int) -> Void) {
                    completionHandler(2)
                    C.iStatic = 1
                    completionHandler(3)
                }
            }

            C.callTest()
            """),
            Example("""
            class C {
                var iInstance: Int = 0

                func callTest() {
                    test { [iInstance] j in
                        print(iInstance, j)
                    }
                }

                func test(_ completionHandler: @escaping (Int) -> Void) {
                }
            }
            """)
        ],
        requiresFileOnDisk: true
    )

    var configuration = SeverityConfiguration(.warning)

    init() {}

    func collectInfo(for file: SwiftLintFile, compilerArguments: [String]) -> CaptureVariableRule.FileInfo {
        file.declaredVariables(compilerArguments: compilerArguments)
    }

    func validate(file: SwiftLintFile, collectedInfo: [SwiftLintFile: CaptureVariableRule.FileInfo],
                  compilerArguments: [String]) -> [StyleViolation] {
        file.captureListVariables(compilerArguments: compilerArguments)
            .filter { capturedVariable in collectedInfo.values.contains { $0.contains(capturedVariable.usr) } }
            .map {
                StyleViolation(ruleDescription: Self.description,
                               severity: configuration.severity,
                               location: Location(file: file, byteOffset: $0.offset))
            }
    }
}

private extension SwiftLintFile {
    static var checkedDeclarationKinds: [SwiftDeclarationKind] {
        [.varClass, .varGlobal, .varInstance, .varStatic]
    }

    func captureListVariableOffsets() -> Set<ByteCount> {
        Self.captureListVariableOffsets(parentEntity: structureDictionary)
    }

    static func captureListVariableOffsets(parentEntity: SourceKittenDictionary) -> Set<ByteCount> {
        parentEntity.substructure
            .reversed()
            .reduce(into: (foundOffsets: Set<ByteCount>(), afterClosure: nil as ByteCount?)) { acc, entity in
                guard let offset = entity.offset else { return }

                if entity.expressionKind == .closure {
                    acc.afterClosure = offset
                } else if let closureOffset = acc.afterClosure,
                          closureOffset < offset,
                          let length = entity.length,
                          let nameLength = entity.nameLength,
                          entity.declarationKind == .varLocal {
                    acc.foundOffsets.insert(offset + length - nameLength)
                } else {
                    acc.afterClosure = nil
                }

                acc.foundOffsets.formUnion(captureListVariableOffsets(parentEntity: entity))
            }
            .foundOffsets
    }

    func captureListVariables(compilerArguments: [String]) -> Set<CaptureVariableRule.Variable> {
        let offsets = self.captureListVariableOffsets()
        guard !offsets.isEmpty, let indexEntities = index(compilerArguments: compilerArguments) else { return Set() }

        return Set(indexEntities.traverseEntitiesDepthFirst {
            guard
                let kind = $0.kind,
                kind.hasPrefix("source.lang.swift.ref.var."),
                let usr = $0.usr,
                let line = $0.line,
                let column = $0.column,
                let offset = stringView.byteOffset(forLine: line, bytePosition: column)
            else { return nil }
            return offsets.contains(offset) ? CaptureVariableRule.Variable(usr: usr, offset: offset) : nil
        })
    }

    func declaredVariableOffsets() -> Set<ByteCount> {
        Self.declaredVariableOffsets(parentStructure: structureDictionary)
    }

    static func declaredVariableOffsets(parentStructure: SourceKittenDictionary) -> Set<ByteCount> {
        Set(
            parentStructure.traverseDepthFirst {
                let hasSetter = $0.setterAccessibility != nil
                let isAutoUnwrap = $0.typeName?.hasSuffix("!") ?? false
                guard
                    hasSetter,
                    !isAutoUnwrap,
                    let declarationKind = $0.declarationKind,
                    checkedDeclarationKinds.contains(declarationKind),
                    !$0.enclosedSwiftAttributes.contains(.lazy),
                    let nameOffset = $0.nameOffset
                else { return [] }
                return [nameOffset]
            }
        )
    }

    func declaredVariables(compilerArguments: [String]) -> Set<CaptureVariableRule.USR> {
        let offsets = self.declaredVariableOffsets()
        guard !offsets.isEmpty, let indexEntities = index(compilerArguments: compilerArguments) else { return Set() }

        return Set(indexEntities.traverseEntitiesDepthFirst {
            guard
                let declarationKind = $0.declarationKind,
                Self.checkedDeclarationKinds.contains(declarationKind),
                let line = $0.line,
                let column = $0.column,
                let offset = stringView.byteOffset(forLine: line, bytePosition: column),
                offsets.contains(offset)
            else { return nil }
            return $0.usr
        })
    }

    func index(compilerArguments: [String]) -> SourceKittenDictionary? {
        guard
            let path = self.path,
            let response = try? Request.index(file: path, arguments: compilerArguments).sendIfNotDisabled()
        else {
            queuedPrintError("""
                Could not index file at path '\(self.path ?? "...")' with the \
                \(CaptureVariableRule.description.identifier) rule.
                """)
            return nil
        }

        return SourceKittenDictionary(response)
    }
}

private extension SourceKittenDictionary {
    var usr: String? { value["key.usr"] as? String }
}
