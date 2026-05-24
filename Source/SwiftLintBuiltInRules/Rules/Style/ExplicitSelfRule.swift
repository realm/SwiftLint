import Foundation
import SourceKittenFramework
import SwiftSyntax

struct ExplicitSelfRule: CorrectableRule, AnalyzerRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "explicit_self",
        name: "Explicit Self",
        description: "Instance variables and functions should be explicitly accessed with 'self.'",
        kind: .style,
        nonTriggeringExamples: ExplicitSelfRuleExamples.nonTriggeringExamples,
        triggeringExamples: ExplicitSelfRuleExamples.triggeringExamples,
        corrections: ExplicitSelfRuleExamples.corrections,
        requiresFileOnDisk: true
    )

    func validate(file: SwiftLintFile, compilerArguments: [String]) -> [StyleViolation] {
        violationRanges(in: file, compilerArguments: compilerArguments).map {
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    func correct(file: SwiftLintFile, compilerArguments: [String]) -> Int {
        let violations = violationRanges(in: file, compilerArguments: compilerArguments)
        let matches = file.ruleEnabled(violatingRanges: violations, for: self)
        if matches.isEmpty {
            return 0
        }
        var contents = file.contents.bridge()
        for range in matches.reversed() {
            contents = contents.replacingCharacters(in: range, with: "self.").bridge()
        }
        file.write(contents.bridge())
        return matches.count
    }

    private func violationRanges(in file: SwiftLintFile, compilerArguments: [String]) -> [NSRange] {
        guard compilerArguments.isNotEmpty, let filePath = file.path else {
            Issue.missingCompilerArguments(path: file.path, ruleID: Self.identifier).print()
            return []
        }
        let contents = file.stringView
        return DeclReferenceOffsetCollector(filePath: filePath, compilerArguments: compilerArguments)
            .walk(tree: file.syntaxTree, handler: \.offsets)
            .compactMap { contents.byteRangeToNSRange(ByteRange(location: $0, length: 0)) }
    }
}

private final class DeclReferenceOffsetCollector: SyntaxVisitor {
    private(set) var offsets: [ByteCount] = []

    private let filePath: String
    private let compilerArguments: [String]

    private static let kindsToFind: Set = [
        "source.lang.swift.ref.function.method.instance",
        "source.lang.swift.ref.var.instance",
    ]

    init(filePath: String, compilerArguments: [String]) {
        self.filePath = filePath
        self.compilerArguments = compilerArguments
        super.init(viewMode: .sourceAccurate)
    }

    override func visitPost(_ node: DeclReferenceExprSyntax) {
        guard node.keyPathInParent != \MemberAccessExprSyntax.declName,
              node.keyPathInParent != \KeyPathPropertyComponentSyntax.declName else {
            return
        }
        let cursorInfoRequest = Request.cursorInfoWithoutSymbolGraph(
            file: filePath,
            offset: ByteCount(node.baseName.positionAfterSkippingLeadingTrivia),
            arguments: compilerArguments
        )
        do {
            let cursorInfo = try cursorInfoRequest.sendIfNotDisabled()
            if let kind = SourceKittenDictionary(cursorInfo).kind, Self.kindsToFind.contains(kind) {
                offsets.append(ByteCount(node.baseName.positionAfterSkippingLeadingTrivia))
            }
        } catch {
            queuedPrintError(String(describing: error))
        }
    }
}
