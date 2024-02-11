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
            Example("f()"),
            Example("f(true)"),
            Example("f(true, false, true)"),
            Example("f(a // line comment)"),
            Example("f(a /* block comment */)"),
            Example("f(true, /* comment */, false)"),
            Example("f(/* comment */ true /* other comment */)"),
            Example("f(/* comment */ true /* other comment */, false)"),
            Example("f(true /* other comment */, /* comment */ false /* other comment */, false // line comment)"),
            Example("""
            f(
            /* comment */
                a: true,
                b: true,
            )
            """),
            Example("""
            f(
                a: true, // line comment
                b: true, // line comment
            )
            """)
        ],
        triggeringExamples: [
            Example("f(↓ )"),
            Example("f(↓  )"),
            Example("f(↓\t)"),
            Example("f(↓  true↓  )"),
            Example("f(↓ /* comment */ true /* other comment */ ↓)"),
            Example("f(↓ x: 0, y: 0↓ )"),
            Example("f(↓ true,↓  false, true↓  )"),
            Example("f(↓ true,↓  false,↓  /* other comment */  ↓true↓   )")
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
  var isLineComment: Bool {
    if case .lineComment = self {
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
      guard let leftParen = node.leftParen else { return }
      checkSpaces(arguments: node.arguments, leftParen: leftParen)
    }
    func checkSpaces(arguments: LabeledExprListSyntax?, leftParen: TokenSyntax) {
      checkLeftParenTrailingTrivia(leftParen: leftParen)
      if let arguments {
        arguments.enumerated().forEach { index, arg in
          // check argument if index is last
          if index == arguments.count - 1 {
            checkArgumentTrailingTrivia(argument: arguments.last)
          }
          guard let trailingComma = arg.trailingComma else { return }
          checkTrailingComma(trailingComma: trailingComma)
        }
      }
    }
    private func checkLeftParenTrailingTrivia(leftParen: TokenSyntax) {
      leftParen.trailingTrivia.pieces.enumerated().forEach { index, trivia in
        if (trivia.isSpaces || trivia.isTabs) && (index == 0 || leftParen.trailingTrivia.count == 1) {
          violations.append(leftParen.endPositionBeforeTrailingTrivia)
        } else if trivia.isSingleSpace && leftParen.trailingTrivia.count - 1 == index {
          return
        } else if trivia.isSpaces || trivia.isTabs {
          violations.append(leftParen.endPosition)
        }
      }
    }
    private func checkArgumentTrailingTrivia(argument: LabeledExprListSyntax.Element?) {
      if let argument {
        guard !argument.trailingTrivia.pieces.isEmpty else { return }
        for index in 0 ..< argument.trailingTrivia.pieces.count {
          let trivia = argument.trailingTrivia.pieces[index]
          if index < argument.trailingTrivia.pieces.count - 1 {
            let next = argument.trailingTrivia.pieces[index + 1]
            if trivia.isSingleSpace && (next.isBlockComment || next.isLineComment) { continue }
          }
          let isInitialOrSinglePiece = index == 0 || argument.trailingTrivia.pieces.count == 1
          if (trivia.isSpaces || trivia.isTabs) && isInitialOrSinglePiece {
            violations.append(argument.endPositionBeforeTrailingTrivia)
          } else if trivia.isSpaces || trivia.isTabs {
            violations.append(argument.endPosition)
          }
        }
      }
    }
    private func checkTrailingComma(trailingComma: TokenSyntax) {
      for index in 0 ..< trailingComma.trailingTrivia.pieces.count {
          let trivia = trailingComma.trailingTrivia.pieces[index]

          if index < trailingComma.trailingTrivia.pieces.count - 1 {
              let next = trailingComma.trailingTrivia.pieces[index + 1]
            if trivia.isSingleSpace && (next.isBlockComment || next.isLineComment) { continue }
          }

          if !trivia.isSingleSpace && (index == 0 || trailingComma.trailingTrivia.count == 1) {
              violations.append(trailingComma.endPositionBeforeTrailingTrivia)
          } else if !trivia.isSingleSpace && !trivia.isBlockComment && !trivia.isLineComment {
              violations.append(trailingComma.endPosition)
          }
      }
    }
  }
}
