import SwiftSyntax
import SwiftLintCore

@SwiftSyntaxRule(explicitRewriter: true, optIn: true)
struct PreferUnknownDefaultRule: Rule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "prefer_unknown_default",
    name: "Prefer Unknown Default",
    description: "Default switch cases should use the `@unknown` attribute.",
    rationale: "Requires the `@unknown` attribute on default switch cases to promote exhaustive handling.",
    kind: .lint,
    nonTriggeringExamples: nonTriggeringExamples,
    triggeringExamples: triggeringExamples,
    corrections: corrections
  )

  static let nonTriggeringExamples = [
    // use of @unknown default should not trigger
    Example("""
      switch (many, cases) {
      case (.known1, _): break
      @unknown default:
          break
      }
    """),
    // exhaustive handling should not trigger
    Example("""
      switch oneCase {
      case .one:
          break
      }
    """),
    // handling of all known non-frozen values & @unknown default should not trigger
    Example("""
      switch nonFrozen {
      case .known1:
          break
      case .known2: break
      @unknown default:
          break
      }
    """),
    // don't trigger on detailed commentary
    Example("""
    /// A detailed example:
    /// ```swift
    /// switch () { default: break }
    /// ```
    """),
  ]

  static let triggeringExamples = [
    Example("""
      switch notExhaustive {
      case .one:
          break
      ↓default:
          break
      }
    """),
    Example("""
      switch someNonFrozenEnumCase {
      case .known1: break
      ↓default:
          return
      }
    """),
  ]

  static let corrections = [
    // example
    Example("""
      switch case {
      case .one:
          break
      case .two: break
      default:
          break
      }
    """)
    : Example("""
      switch case {
      case .one:
          break
      case .two: break
      @unknown default:
          break
      }
    """),
    // example
    Example("""
      switch case { case .one: break; default: break }
    """)
    : Example("""
      switch case { case .one: break; @unknown default: break }
    """),
    // example
    Example("""
      switch value { case .one: break;
        /*nice comment
        placement*/default:
          assertionFailure()
        case .two:
          break
      }
    """)
    : Example("""
      switch value { case .one: break;
        /*nice comment
        placement*/@unknown default:
          assertionFailure()
        case .two:
          break
      }
    """),
  ]
}

extension PreferUnknownDefaultRule {
  final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
    override func visitPost(_ node: SwitchDefaultLabelSyntax) {
      guard let parent = node.parent?.as(SwitchCaseSyntax.self) else {
        // unexpected state... should (can?) we do something?
        return
      }

      // Already have the '@unknown' attribute
      if parent.attribute != nil { return }

      violations.append(
        ReasonedRuleViolation(
          position: node.positionAfterSkippingLeadingTrivia,
          reason: "Default switch cases should use the '@unknown' attribute",
          severity: configuration.severity
        )
      )
    }
  }

  final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
    override func visit(_ node: SwitchCaseSyntax) -> SwitchCaseSyntax {
      // Check if this is a default case without the @unknown attribute
      guard case .default = node.label,
            node.attribute == nil else {
        // Not a default case or already has @unknown attribute
        return super.visit(node)
      }

      // Create the @unknown attribute
      let unknownAttribute = AttributeSyntax(
        leadingTrivia: node.leadingTrivia, // absorb the existing leading trivia
        atSign: .atSignToken(),
        attributeName: IdentifierTypeSyntax(
          name: .identifier("unknown")
        ),
        trailingTrivia: .space
      )

      // Create the replacement node
      var newNode = consume node
      newNode.leadingTrivia = [] // leading trivia was transferred to the attribute
      newNode.attribute = unknownAttribute

      // Mark the violation as corrected
      numberOfCorrections += 1

      return super.visit(newNode)
    }
  }
}
