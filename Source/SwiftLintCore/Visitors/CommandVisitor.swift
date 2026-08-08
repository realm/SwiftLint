import Foundation
import SwiftSyntax

// MARK: - CommandVisitor

/// Visits the source syntax tree to collect all SwiftLint-style comment commands.
final class CommandVisitor: SyntaxVisitor {
    private(set) var commands: [Command] = []
    let locationConverter: SourceLocationConverter

    // Computed once per file: `SourceLocationConverter.sourceLines` materializes every line of the
    // file as a new `[String]` on each access, and a command is resolved against it for every
    // command comment in the file.
    private lazy var sourceLines = locationConverter.sourceLines

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
                let line = sourceLines[location.line - 1]
                guard let character = line.characterPosition(of: location.column) else {
                    break
                }
                let command = Command(
                    commandString: String(comment[lower...]),
                    line: location.line,
                    range: character..<(character + piece.sourceLength.utf8Length - offset)
                )
                commands.append(command)
            default:
                break
            }
            position += piece.sourceLength
        }
    }
}
