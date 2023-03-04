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

private extension TriviaPiece {
    func actionString() -> String? {
        let commandString = "swiftlint:"
        switch self {
        case .lineComment(let comment):
            if
                let lower = comment.range(of: commandString)?.lowerBound,
                case let actionString = String(comment[lower...])
            {
                return actionString
            }
        case .blockComment(let comment):
            if let lower = comment.range(of: commandString)?.lowerBound {
                var start = comment.startIndex
                var end = comment.startIndex
                var contentsEnd = comment.startIndex
                let endOfCommand = comment.index(lower, offsetBy: commandString.count)
                comment.getLineStart(&start, end: &end, contentsEnd: &contentsEnd, for: lower..<endOfCommand)
                let actionString = comment[lower..<contentsEnd]
                return String(actionString)
            }
        default:
            return nil
        }
        return nil
    }
}

private extension Trivia {
    func commands(offset: AbsolutePosition, locationConverter: SourceLocationConverter) -> [Command] {
        var triviaOffset = SourceLength.zero
        var results: [Command] = []
        for trivia in self {
            triviaOffset += trivia.sourceLength
            if
                let actionString = trivia.actionString(),
                case let end = locationConverter.location(for: offset + triviaOffset),
                let line = end.line,
                let column = end.column
            {
                let command = Command(actionString: actionString, line: line, character: column)
                results.append(command)
            }
        }

        return results
    }
}
