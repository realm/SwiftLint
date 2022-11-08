import SwiftSyntax

// MARK: - MarkRule

public struct MarkRule: CorrectableRule, ConfigurationProviderRule, SourceKitFreeRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "mark",
        name: "Mark",
        description: "MARK comment should be in valid format. e.g. '// MARK: ...' or '// MARK: - ...'",
        kind: .lint,
        nonTriggeringExamples: [
            Example("// MARK: good\n"),
            Example("// MARK: - good\n"),
            Example("// MARK: -\n"),
            Example("// BOOKMARK"),
            Example("//BOOKMARK"),
            Example("// BOOKMARKS"),
            issue1749Example
        ],
        triggeringExamples: [
            Example("↓//MARK: bad"),
            Example("↓// MARK:bad"),
            Example("↓//MARK:bad"),
            Example("↓//  MARK: bad"),
            Example("↓// MARK:  bad"),
            Example("↓// MARK: -bad"),
            Example("↓// MARK:- bad"),
            Example("↓// MARK:-bad"),
            Example("↓//MARK: - bad"),
            Example("↓//MARK:- bad"),
            Example("↓//MARK: -bad"),
            Example("↓//MARK:-bad"),
            Example("↓//Mark: bad"),
            Example("↓// Mark: bad"),
            Example("↓// MARK bad"),
            Example("↓//MARK bad"),
            Example("↓// MARK - bad"),
            Example("↓//MARK : bad"),
            Example("↓// MARKL:"),
            Example("↓// MARKR "),
            Example("↓// MARKK -"),
            Example("↓/// MARK:"),
            Example("↓/// MARK bad"),
            issue1029Example
        ],
        corrections: [
            Example("↓//MARK: comment"): Example("// MARK: comment"),
            Example("↓// MARK:  comment"): Example("// MARK: comment"),
            Example("↓// MARK:comment"): Example("// MARK: comment"),
            Example("↓//  MARK: comment"): Example("// MARK: comment"),
            Example("↓//MARK: - comment"): Example("// MARK: - comment"),
            Example("↓// MARK:- comment"): Example("// MARK: - comment"),
            Example("↓// MARK: -comment"): Example("// MARK: - comment"),
            Example("↓// MARK: -  comment"): Example("// MARK: - comment"),
            Example("↓// Mark: comment"): Example("// MARK: comment"),
            Example("↓// Mark: - comment"): Example("// MARK: - comment"),
            Example("↓// MARK - comment"): Example("// MARK: - comment"),
            Example("↓// MARK : comment"): Example("// MARK: comment"),
            Example("↓// MARKL:"): Example("// MARK:"),
            Example("↓// MARKL: -"): Example("// MARK: -"),
            Example("↓// MARKK "): Example("// MARK:"),
            Example("↓// MARKK -"): Example("// MARK: -"),
            Example("↓/// MARK:"): Example("// MARK:"),
            Example("↓/// MARK comment"): Example("// MARK: comment"),
            // issue1029Example: issue1029Correction,
            issue1749Example: issue1749Correction
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        MarkRuleVisitor(locationConverter: file.locationConverter!)
            .walk(file: file, handler: \.positions)
            .map { position in
                StyleViolation(ruleDescription: Self.description,
                               severity: configuration.severity,
                               location: Location(file: file, position: position))
            }
    }

    public func correct(file: SwiftLintFile) -> [Correction] {
        guard let locationConverter = file.locationConverter else {
            return []
        }

        let disabledRegions = file.regions()
            .filter { $0.isRuleDisabled(self) }
            .compactMap { $0.toSourceRange(locationConverter: locationConverter) }

        let rewriter = MarkRuleRewriter(locationConverter: locationConverter,
                                        disabledRegions: disabledRegions)
        let newTree = rewriter
            .visit(file.syntaxTree!)
        guard rewriter.sortedPositions.isNotEmpty else { return [] }

        file.write(newTree.description)
        return rewriter.sortedPositions.map { position in
            Correction(
                ruleDescription: Self.description,
                location: Location(file: file, position: position)
            )
        }
    }
}

// MARK: - MarkRuleVisitor

private final class MarkRuleVisitor: SyntaxVisitor {
    private(set) var positions: [AbsolutePosition] = []
    let locationConverter: SourceLocationConverter

    init(locationConverter: SourceLocationConverter) {
        self.locationConverter = locationConverter
        super.init()
    }

    override func visitPost(_ node: TokenSyntax) {
        positions.append(contentsOf: node.violations(locationConverter: locationConverter))
    }
}

// MARK: - MarkRuleRewriter

private final class MarkRuleRewriter: SyntaxRewriter {
    private var positions: [AbsolutePosition] = []
    var sortedPositions: [AbsolutePosition] { positions.sorted() }
    let locationConverter: SourceLocationConverter
    let disabledRegions: [SourceRange]

    init(locationConverter: SourceLocationConverter, disabledRegions: [SourceRange]) {
        self.locationConverter = locationConverter
        self.disabledRegions = disabledRegions
    }

    override func visit(_ token: TokenSyntax) -> Syntax {
        let violations = token.violations(locationConverter: locationConverter)
        guard let firstViolation = violations.first else {
            return Syntax(token)
        }

        let isInDisabledRegion = disabledRegions.contains { region in
            region.contains(firstViolation, locationConverter: locationConverter)
        }

        guard !isInDisabledRegion else {
            return Syntax(token)
        }

        positions.append(contentsOf: violations)

        var token = token
        token.leadingTrivia = Trivia(pieces: token.leadingTrivia.map { piece in
            if case let .lineComment(comment) = piece, comment.isInvalidMarkComment {
                return .lineComment(comment.fixingMarkCommentFormat())
            } else if case let .docLineComment(comment) = piece, comment.isInvalidMarkComment {
                return .lineComment(comment.fixingMarkCommentFormat())
            } else {
                return piece
            }
        })

        return Syntax(token)
    }
}

// MARK: - Private Helpers

private extension TokenSyntax {
    func violations(locationConverter: SourceLocationConverter) -> [AbsolutePosition] {
        leadingTrivia.violations(offset: position, locationConverter: locationConverter) +
            trailingTrivia.violations(offset: endPositionBeforeTrailingTrivia, locationConverter: locationConverter)
    }
}

private extension Trivia {
    func violations(offset: AbsolutePosition, locationConverter: SourceLocationConverter) -> [AbsolutePosition] {
        var triviaOffset = SourceLength.zero
        var results: [AbsolutePosition] = []
        for trivia in self {
            switch trivia {
            case .lineComment(let comment), .docLineComment(let comment):
                if comment.isInvalidMarkComment {
                    results.append(offset + triviaOffset)
                }
            default:
                break
            }
            triviaOffset += trivia.sourceLength
        }

        return results
    }
}

private let issue1029Example = Example("""
    ↓//MARK:- Top-Level bad mark
    ↓//MARK:- Another bad mark
    struct MarkTest {}
    ↓// MARK:- Bad mark
    extension MarkTest {}
    """)

private let issue1029Correction = Example("""
    // MARK: - Top-Level bad mark
    // MARK: - Another bad mark
    struct MarkTest {}
    // MARK: - Bad mark
    extension MarkTest {}
    """)

// https://github.com/realm/SwiftLint/issues/1749
// https://github.com/realm/SwiftLint/issues/3841
private let issue1749Example = Example(
    """
    /*
    func test1() {
    }
    //MARK: mark
    func test2() {
    }
    */
    """
)

private let issue1749Correction = issue1749Example

private extension String {
    var isInvalidMarkComment: Bool {
        if self == "// MARK:" {
            return false
        } else if self == "// MARK: -" {
            return false
        } else if starts(with: "// MARK:  ") {
            return true
        } else if starts(with: "// MARK: -  ") {
            return true
        } else if starts(with: "// MARK: -") && !starts(with: "// MARK: - ") {
            return true
        } else if starts(with: "// Mark ") || starts(with: "// mark ") {
            return false
        } else if starts(with: "/// Mark ") || starts(with: "/// mark ") {
            return false
        }

        let lowercaseComponents = lowercased().split(separator: " ")
        if lowercaseComponents.first?.starts(with: "//mark") == true {
            return true
        } else if lowercaseComponents.first?.starts(with: "///mark") == true {
            return true
        } else if lowercaseComponents.count < 2 {
            return false
        } else if lowercaseComponents[0] == "///" && (split(separator: " ")[1] == "MARK" ||
                                                      split(separator: " ")[1] == "MARK:") {
            return true
        } else if lowercaseComponents[0] == "//" && lowercaseComponents[1].starts(with: "mark") &&
                    !starts(with: "// MARK: ") {
            return true
        } else {
            return false
        }
    }

    func fixingMarkCommentFormat() -> String {
        guard isInvalidMarkComment else {
            return self
        }
        if contains("-") {
            let body = drop(while: { $0 != "-" }).dropFirst().drop(while: \.isWhitespace)
            if body.isEmpty {
                return "// MARK: -"
            } else {
                return "// MARK: - \(body)"
            }
        } else if contains(":"), let body = split(separator: ":")[safe: 1]?.drop(while: \.isWhitespace) {
            let components = split(separator: ":")
            if components.count == 1 || body.isEmpty {
                return "// MARK:"
            } else {
                return "// MARK: \(body)"
            }
        } else if case let components = split(separator: " "), components.count > 2,
                  components[1].lowercased() == "mark" {
            let body = Array(components).dropFirst(2).joined(separator: " ")
            return "// MARK: \(body)"
        } else {
            return "// MARK:"
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Iterator.Element? {
        return index < count && index >= 0 ? self[index] : nil
    }
}
