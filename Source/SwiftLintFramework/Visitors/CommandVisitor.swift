import SwiftSyntax

// MARK: - CommandVisitor

/// Visits the source syntax tree to collect all SwiftLint-style comment commands.
final class CommandVisitor: SyntaxVisitor {
    private(set) var commands: [Command] = []
    let locationConverter: SourceLocationConverter

    init(locationConverter: SourceLocationConverter) {
        self.locationConverter = locationConverter
        super.init(viewMode: .sourceAccurate)
    }

    override func visitPost(_ node: TokenSyntax) {
        let leadingCommands = node.leadingTrivia.commands(offset: node.position,
                                                          locationConverter: locationConverter)
        let trailingCommands = node.trailingTrivia.commands(offset: node.endPositionBeforeTrailingTrivia,
                                                            locationConverter: locationConverter)
        self.commands.append(contentsOf: leadingCommands + trailingCommands)
    }
}

// MARK: - Private Helpers

private extension Trivia {
    func commands(offset: AbsolutePosition, locationConverter: SourceLocationConverter) -> [Command] {
        var triviaOffset = SourceLength.zero
        var results: [Command] = []
        for trivia in self {
            triviaOffset += trivia.sourceLength
            switch trivia {
            case .lineComment(let comment), .blockComment(let comment):
                if
                    let lower = comment.range(of: "swiftlint:")?.lowerBound,
                    case let actionString = String(comment[lower...]),
                    case let end = locationConverter.location(for: offset + triviaOffset),
                    let line = end.line,
                    let column = end.column
                {
                    let command = Command(actionString: actionString, line: line, character: column)
                    results.append(command)
                }
            default:
                break
            }
        }

        return results
    }
}
