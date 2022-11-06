import Foundation
import SourceKittenFramework

struct TypesafeArrayInitRule: AnalyzerRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "typesafe_array_init",
        name: "Type-safe Array Init",
        description: ArrayInitRule.description.description,
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
                    s.↓map({ $0 })
                }
            """),
            Example("""
                func f(array: [Int]) -> [Int] {
                    array.↓map { $0 }
                }
            """),
            Example("""
                let myInts = [1, 2, 3].↓map { return $0 }
            """),
            Example("""
                struct Generator: Sequence, IteratorProtocol {
                    func next() -> Int? { nil }
                }
                let array = Generator().↓map { i in i }
            """)
        ],
        requiresFileOnDisk: true
    )

    private static let parentRule = ArrayInitRule()
    private static let mapTypePattern = regex("""
            \\Q<Self, T where Self : \\E(?:Sequence|Collection)> \
            \\Q(Self) -> ((Self.Element) throws -> T) throws -> [T]\\E
            """)

    func validate(file: SwiftLintFile, compilerArguments: [String]) -> [StyleViolation] {
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
        return Self.parentRule.validate(file: file)
            .filter { violation in
                guard let offset = getOffset(in: file, at: violation.location) else {
                    return false
                }
                let cursorInfo = Request.cursorInfo(file: filePath, offset: offset, arguments: compilerArguments)
                guard let request = try? cursorInfo.sendIfNotDisabled() else {
                    return false
                }
                return pointsToSystemMapType(pointee: request)
            }
    }

    private func pointsToSystemMapType(pointee: [String: SourceKitRepresentable]) -> Bool {
        if let isSystem = pointee["key.is_system"], isSystem.isEqualTo(true),
           let name = pointee["key.name"], name.isEqualTo("map(_:)"),
           let typeName = pointee["key.typename"] as? String {
            return Self.mapTypePattern.numberOfMatches(in: typeName, range: typeName.fullNSRange) == 1
        }
        return false
    }

    private func getOffset(in file: SwiftLintFile, at location: Location) -> ByteCount? {
        guard let line = location.line, let offset = location.character else {
            return nil
        }
        return file.stringView.byteOffset(forLine: Int64(line), bytePosition: Int64(offset))
    }
}
