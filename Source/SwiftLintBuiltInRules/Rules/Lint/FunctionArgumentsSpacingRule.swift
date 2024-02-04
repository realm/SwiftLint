import SwiftSyntax

@SwiftSyntaxRule
struct FunctionArgumentsSpacingRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "functions_arguments_spacing",
        name: "Function Arguments Spacing",
        description: "Remove the space before the first function argument and after the last argument",
        kind: .lint,
        nonTriggeringExamples: [
            Example("testFunc()"),
            Example("testFunc(style)"),
            Example("testFunc(true, false)"),
            Example("""
            testFunc(
                a: true,
                b: false
            )
            """)
        ],
        triggeringExamples: [
            Example("testFunc(↓ )"),
            Example("testFunc(↓  )"),
            Example("testFunc(↓ style)"),
            Example("testFunc(↓  style)"),
            Example("testFunc(style ↓)"),
            Example("testFunc(↓  style  ↓)"),
            Example("testFunc(↓ style ↓)"),
            Example("testFunc(↓ offset: 0, limit: 0)"),
            Example("testFunc(offset: 0, limit: 0 ↓)"),
            Example("testFunc(↓ 1, 2, 3 ↓)"),
            Example("testFunc(↓ 1,  ↓2, 3 ↓)"),
            Example("testFunc(↓ 1,  ↓2,   ↓3 ↓)"),
            Example("testFunc(↓ /* comment */ a)"),
            Example("testFunc(a /* other comment */ ↓)"),
            Example("testFunc(↓ /* comment */ a /* other comment */)"),
            Example("testFunc(/* comment */ a /* other comment */ ↓)"),
            Example("testFunc(↓ /* comment */ a /* other comment */ ↓)"),
            Example("testFunc(↓  /* comment */ a /* other comment */  ↓)"),
            Example("testFunc(↓  /* comment */  ↓a↓   /* other comment */  ↓)"),
        ]
    )
}

private extension TriviaPiece {
  var isSingleSpace: Bool {
    if case .spaces(1) = self {
      return true
    } else {
      return false
    }
  }
    var isSpaces: Bool {
        if case .spaces = self {
            return true
        } else {
            return false
        }
    }
    var isTabs: Bool {
      if case .tabs = self {
            return true
        } else {
            return false
        }
    }
    var isBlockComment: Bool {
      if case .blockComment = self {
            return true
        } else {
            return false
        }
    }
}

private extension FunctionArgumentsSpacingRule {
  final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      guard let leftParen = node.leftParen, let rightParen = node.rightParen else { return }
      let arguments = node.arguments
      if arguments.isEmpty {
        if let triviaAfterLeftParen = leftParen.trailingTrivia.pieces.first {
          if triviaAfterLeftParen.isSpaces {
            violations.append(leftParen.endPositionBeforeTrailingTrivia)
          }
        }
      }
      if arguments.count == 1 {
        if let firstArg = node.arguments.first {
          if let triviaAfterLeftParen = leftParen.trailingTrivia.pieces.first {
            if triviaAfterLeftParen.isSpaces && !firstArg.leadingTrivia.containsNewlines() {
              violations.append(leftParen.endPositionBeforeTrailingTrivia)
            }
          }
          if let lastTriviaAfterLeftParan = leftParen.trailingTrivia.pieces.last {
            if !lastTriviaAfterLeftParan.isSingleSpace && leftParen.trailingTrivia.pieces.count >= 2 {
              violations.append(leftParen.endPosition)
            }
          }
          if firstArg.trailingTrivia.pieces.isNotEmpty {
            if firstArg.trailingTrivia.pieces.count == 1 && firstArg.trailingTrivia.pieces.first!.isSpaces {
              violations.append(firstArg.endPosition)
            }

            if firstArg.trailingTrivia.pieces.first!.isSpaces && firstArg.trailingTrivia.pieces.count >= 2 && !firstArg.trailingTrivia.pieces.last!.isBlockComment {
              violations.append(firstArg.endPosition)
            }

            if firstArg.trailingTrivia.pieces.count >= 2 && !firstArg.trailingTrivia.pieces.first!.isSingleSpace {
              violations.append(firstArg.endPositionBeforeTrailingTrivia)
            }
          }
        }
      }
      if arguments.count >= 2 {
        arguments.enumerated().forEach { index, arg in
          if index == 0 {
            if let triviaAfterLeftParen = leftParen.trailingTrivia.pieces.first {
              if triviaAfterLeftParen.isSpaces && !arg.leadingTrivia.containsNewlines() {
                violations.append(leftParen.endPositionBeforeTrailingTrivia)
              }
            }
            let trailingComma = arg.trailingComma
            guard let _trailingComma = trailingComma else { return }
            guard let trailingTrivia = _trailingComma.trailingTrivia.pieces.first else { return }
            if !(trailingTrivia.isSingleSpace) {
              violations.append(_trailingComma.endPosition)
            }
          } else if index == arguments.count - 1 {
            if let lastArgument = arguments.last {
              if let triviaAfterLastArgument = lastArgument.trailingTrivia.pieces.first {
                if triviaAfterLastArgument.isSpaces {
                  violations.append(lastArgument.endPosition)
                }
              }
            }
            let trailingComma = arg.trailingComma
            guard let _trailingComma = trailingComma else { return }
            guard let trailingTrivia = _trailingComma.trailingTrivia.pieces.first else { return }
            if !(trailingTrivia.isSingleSpace) {
              violations.append(_trailingComma.endPosition)
            }
          } else {
            let trailingComma = arg.trailingComma
            guard let _trailingComma = trailingComma else { return }
            guard let trailingTrivia = _trailingComma.trailingTrivia.pieces.first else { return }
            if !(trailingTrivia.isSingleSpace) {
              violations.append(_trailingComma.endPosition)
            }
          }
        }
      }
    }
  }
}
