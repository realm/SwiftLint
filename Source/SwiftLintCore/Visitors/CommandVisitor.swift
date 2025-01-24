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
        collectCommands(in: node.leadingTrivia, offset: node.position)
        collectCommands(in: node.trailingTrivia, offset: node.endPositionBeforeTrailingTrivia)
    }

    private func collectCommands(in trivia: Trivia, offset: AbsolutePosition) {
        var position = offset
        for piece in trivia {
            switch piece {
            case .lineComment(let comment):
                guard let lower = comment.range(of: "swiftlint:")?.lowerBound.samePosition(in: comment.utf8) else {
                    break
                }
                let offset = comment.utf8.distance(from: comment.utf8.startIndex, to: lower)
                let location = locationConverter.location(for: position.advanced(by: offset))
                let line = locationConverter.sourceLines[location.line - 1]
                guard let character = line.characterPosition(of: location.column) else {
                    break
                }
                let command = Command(
                    actionString: String(comment[lower...]),
                    line: location.line,
                    character: character
                )
                commands.append(command)
            default:
                break
            }
            position += piece.sourceLength
        }
    }
}
