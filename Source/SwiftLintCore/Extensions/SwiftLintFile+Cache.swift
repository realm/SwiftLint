import Foundation
import SourceKittenFramework
import SwiftDiagnostics
import SwiftIDEUtils
import SwiftOperators
import SwiftParser
import SwiftParserDiagnostics
import SwiftSyntax

// swiftlint:disable:next blanket_disable_command
// swiftlint:disable closure_end_indentation opening_brace

package typealias AssertHandler = () -> Void

// Re-enable once all parser diagnostics in tests have been addressed.
// https://github.com/realm/SwiftLint/issues/3348
@TaskLocal package var parserDiagnosticsDisabledForTests = false

private typealias SourceKitResponse = [String: any SourceKitRepresentable]

/// Wraps a cached value, distinguishing "not yet computed" from "computed (possibly nil)".
private enum Cached<T> {
    case notComputed
    case computing(DispatchGroup)
    case computed(T)
}

/// Per-file cache storing all derived artifacts. One instance lives on each `SwiftLintFile`.
///
/// **Locking strategy**: a concurrent `DispatchQueue` guards all slots.
/// Reads use a plain `sync` (concurrent); writes use `sync(flags: .barrier)` (exclusive).
/// Each accessor computes its value *outside* the lock so that factories may safely access
/// other cached properties without risk of deadlock. Cold slots are marked as computing
/// under a barrier so concurrent first readers wait for the same result.
final class FileCache: @unchecked Sendable {
    fileprivate let lock = NSLock()

    fileprivate var syntaxTree = Cached<SourceFileSyntax>.notComputed
    fileprivate var locationConverter = Cached<SourceLocationConverter>.notComputed
    fileprivate var commands = Cached<[Command]>.notComputed
    fileprivate var syntaxClassifications = Cached<SyntaxClassifications>.notComputed
    fileprivate var linesWithTokens = Cached<Set<Int>>.notComputed
    fileprivate var commentLines = Cached<Set<Int>>.notComputed
    fileprivate var emptyLines = Cached<Set<Int>>.notComputed
    fileprivate var response = Cached<SourceKitResponse?>.notComputed
    fileprivate var structureDictionary = Cached<SourceKittenDictionary?>.notComputed
    fileprivate var foldedSyntaxTree = Cached<SourceFileSyntax?>.notComputed
    fileprivate var syntaxMap = Cached<SwiftLintSyntaxMap?>.notComputed
    fileprivate var swiftSyntaxTokens = Cached<[SwiftLintSyntaxToken]?>.notComputed
    fileprivate var sourceKitFreeSyntaxMapSlot = Cached<SwiftLintSyntaxMap>.notComputed
    fileprivate var commentByteRangesSlot = Cached<[ByteRange]>.notComputed
    fileprivate var assertHandlerSlot = Cached<AssertHandler?>.notComputed

    /// Returns the cached value for a slot, computing it via `factory` on a cache miss.
    /// The factory runs *outside* the lock, so it may safely access other cached properties.
    /// On a concurrent first access the winner's result is kept; the loser's is discarded.
    ///
    /// TODO: [06/05/2028] We can convert the explicit getters and setters to a keypath-based subscript once the Swift
    /// compiler bug https://github.com/swiftlang/swift/issues/69386 is resolved.
    fileprivate func getOrCompute<T>(factory: () -> T, get: () -> Cached<T>, set: (Cached<T>) -> Void) -> T {
        lock.lock()
        switch get() {
        case .computed(let value):
            lock.unlock()
            return value
        case .computing(let group):
            lock.unlock()
            group.wait()
            return getOrCompute(factory: factory, get: get, set: set)
        case .notComputed:
            let group = DispatchGroup()
            group.enter()
            set(.computing(group))
            lock.unlock()
            // The factory runs outside the lock, so it may safely access other cached properties.
            let value = factory()
            lock.lock()
            // The slot may have been invalidated while computing; only publish the result if this
            // computation is still the current one. On a concurrent first access the winner's
            // result is kept; the loser's is discarded.
            if case .computing(let currentGroup) = get(), currentGroup === group {
                set(.computed(value))
            }
            lock.unlock()
            group.leave()
            return value
        }
    }

    /// Resets all slots to `.notComputed`, forcing recomputation on next access.
    fileprivate func invalidateAll() {
        lock.withLock {
            syntaxTree = .notComputed
            locationConverter = .notComputed
            commands = .notComputed
            syntaxClassifications = .notComputed
            linesWithTokens = .notComputed
            commentLines = .notComputed
            emptyLines = .notComputed
            response = .notComputed
            structureDictionary = .notComputed
            foldedSyntaxTree = .notComputed
            syntaxMap = .notComputed
            swiftSyntaxTokens = .notComputed
            sourceKitFreeSyntaxMapSlot = .notComputed
            commentByteRangesSlot = .notComputed
            assertHandlerSlot = .notComputed
        }
    }
}

extension SwiftLintFile {
    public var sourcekitdFailed: Bool {
        get { cachedResponse == nil }
        set {
            fileCache.lock.withLock {
                fileCache.response = newValue ? .computed(nil) : .notComputed
            }
        }
    }

    package var assertHandler: AssertHandler? {
        get {
            fileCache.getOrCompute
                { nil }
                get: { fileCache.assertHandlerSlot }
                set: { fileCache.assertHandlerSlot = $0 }
        }
        set {
            fileCache.lock.withLock { fileCache.assertHandlerSlot = .computed(newValue) }
        }
    }

    public var parserDiagnostics: [String] {
        if parserDiagnosticsDisabledForTests {
            return []
        }
        return ParseDiagnosticsGenerator.diagnostics(for: syntaxTree)
            .filter { $0.diagMessage.severity == .error }
            .map(\.message)
    }

    public var linesWithTokens: Set<Int> {
        fileCache.getOrCompute
            { computeLinesWithTokens() }
            get: { fileCache.linesWithTokens }
            set: { fileCache.linesWithTokens = $0 }
    }

    public var structureDictionary: SourceKittenDictionary {
        let value = fileCache.getOrCompute
            { cachedResponse.map(Structure.init).map { SourceKittenDictionary($0.dictionary) } }
            get: { fileCache.structureDictionary }
            set: { fileCache.structureDictionary = $0 }
        guard let value else {
            if let handler = assertHandler {
                handler()
                return SourceKittenDictionary([:])
            }
            queuedFatalError("Never call this for file that sourcekitd fails.")
        }
        return value
    }

    /// The byte ranges of all comment trivia pieces (line, doc-line, block, and doc-block) in the
    /// file, in source order. Computed once per file and cached; multiple rules share the result.
    ///
    /// Comments are read directly off token trivia rather than via `syntaxClassifications`, which
    /// would additionally run SwiftSyntax's general-purpose classifier over every non-comment token
    /// in the file. Byte positions are tracked incrementally during a single visitor pass because
    /// `SyntaxProtocol.position` and token-sequence iteration climb the tree per call, which
    /// degrades sharply on deeply nested expression trees.
    public func commentByteRanges() -> [ByteRange] {
        fileCache.getOrCompute
            { [file = self] in
                let visitor = CommentByteRangesVisitor(viewMode: .sourceAccurate)
                visitor.walk(file.syntaxTree)
                return visitor.ranges
            }
            get: { fileCache.commentByteRangesSlot }
            set: { fileCache.commentByteRangesSlot = $0 }
    }

    public var syntaxClassifications: SyntaxClassifications {
        fileCache.getOrCompute
            { syntaxTree.classifications }
            get: { fileCache.syntaxClassifications }
            set: { fileCache.syntaxClassifications = $0 }
    }

    public var syntaxMap: SwiftLintSyntaxMap {
        let value = fileCache.getOrCompute
            { cachedResponse.map { SwiftLintSyntaxMap(value: SyntaxMap(sourceKitResponse: $0)) } }
            get: { fileCache.syntaxMap }
            set: { fileCache.syntaxMap = $0 }
        guard let value else {
            if let handler = assertHandler {
                handler()
                return SwiftLintSyntaxMap(value: SyntaxMap(data: []))
            }
            queuedFatalError("Never call this for file that sourcekitd fails.")
        }
        return value
    }

    public var syntaxTree: SourceFileSyntax {
        fileCache.getOrCompute
            { Parser.parse(source: contents) }
            get: { fileCache.syntaxTree }
            set: { fileCache.syntaxTree = $0 }
    }

    public var foldedSyntaxTree: SourceFileSyntax? {
        fileCache.getOrCompute
            {
                OperatorTable.standardOperators
                    .foldAll(syntaxTree) { _ in /* Don't handle errors. */ }
                    .as(SourceFileSyntax.self)
            }
            get: { fileCache.foldedSyntaxTree }
            set: { fileCache.foldedSyntaxTree = $0 }
    }

    public var locationConverter: SourceLocationConverter {
        fileCache.getOrCompute
            { SourceLocationConverter(fileName: path?.filepath ?? "<nopath>", tree: syntaxTree) }
            get: { fileCache.locationConverter }
            set: { fileCache.locationConverter = $0 }
    }

    public var commands: [Command] { cachedCommands.filter(\.isValid) }

    public var invalidCommands: [Command] { cachedCommands.filter { !$0.isValid } }

    public var swiftSyntaxDerivedSourceKittenTokens: [SwiftLintSyntaxToken]? {
        fileCache.getOrCompute
            { SwiftSyntaxKindBridge.sourceKittenSyntaxKinds(for: self) }
            get: { fileCache.swiftSyntaxTokens }
            set: { fileCache.swiftSyntaxTokens = $0 }
    }

    /// A syntax map equivalent to the sourcekitd-backed `syntaxMap`, built from the SwiftSyntax-derived
    /// bridge tokens so that rules using it don't require SourceKit.
    ///
    /// Cached because it is a pure function of the file that several rules ask for independently —
    /// `statement_position` alone builds it four times — and each call otherwise re-derives the whole
    /// token array and syntax map.
    public func sourceKitFreeSyntaxMap() -> SwiftLintSyntaxMap {
        fileCache.getOrCompute
            { computeSourceKitFreeSyntaxMap() }
            get: { fileCache.sourceKitFreeSyntaxMapSlot }
            set: { fileCache.sourceKitFreeSyntaxMapSlot = $0 }
    }

    public var commentLines: Set<Int> {
        fileCache.getOrCompute
            { CommentLinesVisitor.commentLines(in: self) }
            get: { fileCache.commentLines }
            set: { fileCache.commentLines = $0 }
    }

    public var emptyLines: Set<Int> {
        fileCache.getOrCompute
            { EmptyLinesVisitor.emptyLines(in: self) }
            get: { fileCache.emptyLines }
            set: { fileCache.emptyLines = $0 }
    }

    /// Invalidates all cached data for this file.
    public func invalidateCache() {
        if !isVirtual {
            file.clearCaches()
        }
        fileCache.invalidateAll()
    }

    // MARK: - Private helpers

    /// The raw SourceKit response for this file (cached).
    private var cachedResponse: SourceKitResponse? {
        fileCache.getOrCompute
            {
                do {
                    return try Request.editorOpen(file: file).sendIfNotDisabled()
                } catch let error as Request.Error {
                    queuedPrintError(error.description)
                    return nil
                } catch {
                    return nil
                }
            }
            get: { fileCache.response }
            set: { fileCache.response = $0 }
    }

    private var cachedCommands: [Command] {
        fileCache.getOrCompute
            {
                contents.contains("swiftlint:")
                    ? CommandVisitor(locationConverter: locationConverter).walk(file: self, handler: \.commands)
                    : []
            }
            get: { fileCache.commands }
            set: { fileCache.commands = $0 }
    }
}

private final class CommentByteRangesVisitor: SyntaxVisitor {
    private(set) var ranges = [ByteRange]()
    private var position = 0

    override func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
        appendCommentRanges(in: token.leadingTrivia)
        position += token.trimmedLength.utf8Length
        appendCommentRanges(in: token.trailingTrivia)
        return .skipChildren
    }

    private func appendCommentRanges(in trivia: Trivia) {
        for piece in trivia {
            let length = piece.sourceLength.utf8Length
            if piece.isComment {
                ranges.append(ByteRange(location: ByteCount(position), length: ByteCount(length)))
            }
            position += length
        }
    }
}
