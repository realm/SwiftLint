import Foundation
import SwiftSyntax

// workaround for https://bugs.swift.org/browse/SR-10121 so we can use `Self` in a closure
protocol SwiftLintSyntaxVisitor: SyntaxVisitor {}
extension SyntaxVisitor: SwiftLintSyntaxVisitor {}

extension SwiftLintSyntaxVisitor {
    func walk<T>(tree: SourceFileSyntax, handler: (Self) -> T) -> T {
        #if DEBUG
        // workaround for stack overflow when running in debug
        // https://bugs.swift.org/browse/SR-11170
        let lock = NSLock()
        let work = DispatchWorkItem {
            lock.lock()
            self.walk(tree)
            lock.unlock()
        }
        let thread = Thread {
            work.perform()
        }

        thread.stackSize = 8 << 20 // 8 MB.
        thread.start()
        work.wait()

        lock.lock()
        defer {
            lock.unlock()
        }

        return handler(self)
        #else
        walk(tree)
        return handler(self)
        #endif
    }

    func walk<T>(file: SwiftLintFile, handler: (Self) -> [T]) -> [T] {
        guard let syntaxTree = file.syntaxTree else {
            return []
        }

        return walk(tree: syntaxTree, handler: handler)
    }
}

public protocol ViolationsSyntaxVisitor: SyntaxVisitor {
    var violationPositions: [AbsolutePosition] { get }
}

public protocol SwiftSyntaxRule: SourceKitFreeRule {
    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor?
    func makeViolation(file: SwiftLintFile, position: AbsolutePosition) -> StyleViolation
}

public extension SwiftSyntaxRule where Self: ConfigurationProviderRule, ConfigurationType == SeverityConfiguration {
    func makeViolation(file: SwiftLintFile, position: AbsolutePosition) -> StyleViolation {
        StyleViolation(
            ruleDescription: Self.description,
            severity: configuration.severity,
            location: Location(file: file, position: position)
        )
    }
}

public extension SwiftSyntaxRule {
    func disabledRegions(file: SwiftLintFile) -> [SourceRange] {
        guard let locationConverter = file.locationConverter else {
            return []
        }

        return file.regions()
            .filter { $0.isRuleDisabled(self) }
            .compactMap { $0.toSourceRange(locationConverter: locationConverter) }
    }

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        guard let visitor = makeVisitor(file: file) else {
            return []
        }

        return visitor
            .walk(file: file, handler: \.violationPositions)
            .sorted()
            .map { makeViolation(file: file, position: $0) }
    }
}

public protocol ViolationsSyntaxRewriter: SyntaxRewriter {
    var correctionPositions: [AbsolutePosition] { get }
}

public protocol SwiftSyntaxCorrectableRule: SwiftSyntaxRule, CorrectableRule {
    func makeRewriter(file: SwiftLintFile) -> ViolationsSyntaxRewriter?
}

public extension SwiftSyntaxCorrectableRule {
    func correct(file: SwiftLintFile) -> [Correction] {
        guard let rewriter = makeRewriter(file: file),
              let syntaxTree = file.syntaxTree,
              case let newTree = rewriter.visit(syntaxTree),
              rewriter.correctionPositions.isNotEmpty else {
            return []
        }

        file.write(newTree.description)
        return rewriter
            .correctionPositions
            .sorted()
            .map { position in
                Correction(
                    ruleDescription: Self.description,
                    location: Location(file: file, position: position)
                )
            }
    }
}
