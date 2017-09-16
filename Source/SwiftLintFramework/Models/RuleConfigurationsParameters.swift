//
//  RuleConfigurationsParameters.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 09/16/17.
//  Copyright © 2017 Realm. All rights reserved.
//
// Generated using Sourcery 0.8.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

public extension AttributesConfiguration {
    var parameters: [ParameterDefinition] {
        return [
          alwaysOnSameLineParameter,
          alwaysOnNewLineParameter,
          severityParameter
        ]
    }
}

public extension ColonConfiguration {
    var parameters: [ParameterDefinition] {
        return [
          severityParameter,
          flexibleRightSpacingParameter,
          applyToDictionariesParameter
        ]
    }
}

public extension CyclomaticComplexityConfiguration {
    var parameters: [ParameterDefinition] {
        return [
          warningLengthParameter,
          errorLengthParameter,
          ignoresCaseStatementsParameter
        ]
    }
}

public extension DiscouragedDirectInitConfiguration {
    var parameters: [ParameterDefinition] {
        return [
          typesParameter,
          severityParameter
        ]
    }
}

public extension FileHeaderConfiguration {
    var parameters: [ParameterDefinition] {
        return [
          severityParameter,
          requiredStringParameter,
          requiredPatternParameter,
          forbiddenStringParameter,
          forbiddenPatternParameter
        ]
    }
}

public extension FileLengthRuleConfiguration {
    var parameters: [ParameterDefinition] {
        return [
          warningLengthParameter,
          errorLengthParameter,
          ignoreCommentOnlyLinesParameter
        ]
    }
}

public extension ImplicitlyUnwrappedOptionalConfiguration {
    var parameters: [ParameterDefinition] {
        return [
          modeParameter,
          severityParameter
        ]
    }
}

public extension LineLengthConfiguration {
    var parameters: [ParameterDefinition] {
        return [
          warningLengthParameter,
          errorLengthParameter,
          ignoresURLsParameter,
          ignoresFunctionDeclarationsParameter,
          ignoresCommentsParameter
        ]
    }
}

public extension NameConfiguration {
    var parameters: [ParameterDefinition] {
        return [
          minLengthParameter,
          maxLengthParameter,
          excludedParameter,
          allowedSymbolsParameter,
          validatesStartWithLowercaseParameter
        ]
    }
}

public extension NestingConfiguration {
    var parameters: [ParameterDefinition] {
        return [
          typeLevelParameter,
          statementLevelParameter
        ]
    }
}

public extension NumberSeparatorConfiguration {
    var parameters: [ParameterDefinition] {
        return [
          minimumLengthParameter,
          minimumFractionLengthParameter,
          severityParameter
        ]
    }
}

public extension ObjectLiteralConfiguration {
    var parameters: [ParameterDefinition] {
        return [
          imageLiteralParameter,
          colorLiteralParameter,
          severityParameter
        ]
    }
}

public extension OverridenSuperCallConfiguration {
    var parameters: [ParameterDefinition] {
        return [
          severityParameter,
          excludedParameter,
          includedParameter
        ]
    }
}

public extension PrivateOutletRuleConfiguration {
    var parameters: [ParameterDefinition] {
        return [
          allowPrivateSetParameter,
          severityParameter
        ]
    }
}

public extension PrivateOverFilePrivateRuleConfiguration {
    var parameters: [ParameterDefinition] {
        return [
          validateExtensionsParameter,
          severityParameter
        ]
    }
}

public extension ProhibitedSuperConfiguration {
    var parameters: [ParameterDefinition] {
        return [
          severityParameter,
          excludedParameter,
          includedParameter
        ]
    }
}

//public extension RegexConfiguration {
//    var parameters: [ParameterDefinition] {
//        return [
//        ]
//    }
//}

public extension SeverityConfiguration {
    var parameters: [ParameterDefinition] {
        return [
          severityParameter
        ]
    }
}

public extension SeverityLevelsConfiguration {
    var parameters: [ParameterDefinition] {
        return [
          warningParameter,
          errorParameter
        ]
    }
}

public extension StatementConfiguration {
    var parameters: [ParameterDefinition] {
        return [
          statementModeParameter,
          severityParameter
        ]
    }
}

public extension TrailingCommaConfiguration {
    var parameters: [ParameterDefinition] {
        return [
          mandatoryCommaParameter,
          severityParameter
        ]
    }
}

public extension TrailingWhitespaceConfiguration {
    var parameters: [ParameterDefinition] {
        return [
          ignoresEmptyLinesParameter,
          ignoresCommentsParameter,
          severityParameter
        ]
    }
}

public extension UnusedOptionalBindingConfiguration {
    var parameters: [ParameterDefinition] {
        return [
          ignoreOptionalTryParameter,
          severityParameter
        ]
    }
}

public extension VerticalWhitespaceConfiguration {
    var parameters: [ParameterDefinition] {
        return [
          maxEmptyLinesParameter,
          severityParameter
        ]
    }
}
