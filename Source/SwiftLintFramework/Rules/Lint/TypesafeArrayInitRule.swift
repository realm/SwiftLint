import Foundation
import SourceKittenFramework

public struct TypesafeArrayInitRule: AnalyzerRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "typesafe_array_init",
        name: "Type-safe Array Init",
        description: "Prefer using `Array(seq)` over `seq.map { $0 }` to convert a sequence into an Array.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
                enum MyError: Error {}
                let myResult: Result<String, MyError> = .success("")
                let result: Result<Any, MyError> = myResult.map { $0 }
            """),
            Example("""
                struct IntArray {
                    let elements = [1, 2, 3]
                    func map<T>(_ transformer: (Int) throws -> T) rethrows -> [T] {
                        try elements.map(transformer)
                    }
                }
                let ints = IntArray()
                let intsCopy = ints.map { $0 }
            """)
        ],
        triggeringExamples: [
            Example("""
                func f<Seq: Sequence>(s: Seq) -> [Seq.Element] {
                    ↓s.map({ $0 })
                }
            """),
            Example("""
                func f(array: [Int]) -> [Int] {
                    ↓array.map { $0 }
                }
            """),
            Example("""
                let myInts = ↓[1, 2, 3].map { return $0 }
            """),
            Example("""
                struct Generator: Sequence, IteratorProtocol {
                    func next() -> Int? { nil }
                }
                let array = ↓Generator().map { i in i }
            """)
        ],
        requiresFileOnDisk: true
    )

    private static let parentRule = ArrayInitRule()
    private static let mapTypePattern = regex("""
            \\Q<Self, T where Self : \\E(?:Sequence|Collection)> \
            \\Q(Self) -> ((Self.Element) throws -> T) throws -> [T]\\E
            """)

    public func validate(file: SwiftLintFile, compilerArguments: [String]) -> [StyleViolation] {
        guard let filePath = file.path else {
            return []
        }
        guard compilerArguments.isNotEmpty else {
            queuedPrintError("""
                Attempted to lint file at path '\(file.path ?? "...")' with the \
                \(Self.description.identifier) rule without any compiler arguments.
                """)
            return []
        }
        let index = buildIndex(for: filePath, using: compilerArguments)
        return index.traverseEntitiesDepthFirst { substructure -> [StyleViolation]? in
            guard substructure.kind == "source.lang.swift.ref.function.method.instance",
                  let line = substructure.line, let column = substructure.column,
                  let offset = file.stringView.byteOffset(forLine: line, bytePosition: column) else {
                return nil
            }
            let cursorInfoRequest = Request.cursorInfo(file: filePath, offset: offset, arguments: compilerArguments)
            guard let cursorInfo = try? cursorInfoRequest.sendIfNotDisabled(),
                  let isSystem = cursorInfo["key.is_system"], isSystem.isEqualTo(true),
                  let name = cursorInfo["key.name"], name.isEqualTo("map(_:)"),
                  let typeName = cursorInfo["key.typename"] as? String,
                  Self.mapTypePattern.numberOfMatches(in: typeName, range: typeName.fullNSRange) == 1,
                  let dict = pickSubstructure(from: file.structureDictionary, at: offset) else {
                return nil
            }
            return Self.parentRule.validate(file: file, kind: .call, dictionary: dict)
        }.flatMap { $0 }
    }

    private func buildIndex(for filePath: String, using compilerArguments: [String]) -> SourceKittenDictionary {
        do {
            return SourceKittenDictionary(
                try Request.index(file: filePath, arguments: compilerArguments).sendIfNotDisabled()
            )
        } catch {
            queuedPrintError("""
                Indexing of file '\(filePath)' in the context of the \(Self.description.identifier) rule failed.
                """)
        }
        return SourceKittenDictionary([:])
    }

    private func pickSubstructure(from: SourceKittenDictionary, at mapOffset: ByteCount) -> SourceKittenDictionary? {
        let substructures = from.traverseBreadthFirst { substructure -> [SourceKittenDictionary]? in
            guard substructure.expressionKind == .call,
                  let name = substructure.name, name.hasSuffix(".map"),
                  let nameOffset = substructure.nameOffset,
                  let nameLength = substructure.nameLength,
                  mapOffset + ByteCount("map".count) == nameOffset + nameLength else {
                return nil
            }
            return [substructure]
        }
        return substructures.count == 1 ? substructures.first : nil
    }
}
