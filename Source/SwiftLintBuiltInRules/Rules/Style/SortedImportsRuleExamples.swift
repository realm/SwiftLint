internal struct SortedImportsRuleExamples {
    private static let groupByAttributesConfiguration = ["grouping": "attributes"]

    static let nonTriggeringExamples = [
        Example("import AAA\nimport BBB\nimport CCC\nimport DDD"),
        Example("import Alamofire\nimport API"),
        Example("import labc\nimport Ldef"),
        Example("import BBB\n// comment\nimport AAA\nimport CCC"),
        Example("@testable import AAA\nimport   CCC"),
        Example("import AAA\n@testable import   CCC"),
        Example("""
        import EEE.A
        import FFF.B
        #if os(Linux)
        import DDD.A
        import EEE.B
        #else
        import CCC
        import DDD.B
        #endif
        import AAA
        import BBB
        """),
        Example("""
        @testable import AAA
          @testable import BBB
        """, configuration: groupByAttributesConfiguration, excludeFromDocumentation: true),
        Example("""
        @testable import BBB
          import AAA
        """, configuration: groupByAttributesConfiguration, excludeFromDocumentation: true),
        Example("""
        @_exported import BBB
          @testable import AAA
        """, configuration: groupByAttributesConfiguration, excludeFromDocumentation: true),
        Example("""
        @_exported @testable import BBB
          import AAA
        """, configuration: groupByAttributesConfiguration, excludeFromDocumentation: true)
    ]

    static let triggeringExamples = [
        Example("import AAA\nimport ZZZ\nimport ↓BBB\nimport CCC"),
        Example("import DDD\n// comment\nimport CCC\nimport ↓AAA"),
        Example("@testable import CCC\nimport   ↓AAA"),
        Example("import CCC\n@testable import   ↓AAA"),
        Example("""
        import FFF.B
        import ↓EEE.A
        #if os(Linux)
        import DDD.A
        import EEE.B
        #else
        import DDD.B
        import ↓CCC
        #endif
        import AAA
        import BBB
        """),
        Example("""
          @testable import BBB
        @testable import ↓AAA
        """, configuration: groupByAttributesConfiguration, excludeFromDocumentation: true),
        Example("""
          import AAA
        @testable import ↓BBB
        """, configuration: groupByAttributesConfiguration, excludeFromDocumentation: true),
        Example("""
          import BBB
        @testable import ↓AAA
        """, configuration: groupByAttributesConfiguration, excludeFromDocumentation: true),
        Example("""
          @testable import AAA
        @_exported import ↓BBB
        """, configuration: groupByAttributesConfiguration, excludeFromDocumentation: true),
        Example("""
          import AAA
        @_exported @testable import ↓BBB
        """, configuration: groupByAttributesConfiguration, excludeFromDocumentation: true)
    ]

    static let corrections = [
        Example("import AAA\nimport ZZZ\nimport ↓BBB\nimport CCC"):
            Example("import AAA\nimport BBB\nimport CCC\nimport ZZZ"),
        Example("import BBB // comment\nimport ↓AAA"): Example("import AAA\nimport BBB // comment"),
        Example("import BBB\n// comment\nimport CCC\nimport ↓AAA"):
            Example("import BBB\n// comment\nimport AAA\nimport CCC"),
        Example("@testable import CCC\nimport  ↓AAA"): Example("import  AAA\n@testable import CCC"),
        Example("import CCC\n@testable import  ↓AAA"): Example("@testable import  AAA\nimport CCC"),
        Example("""
        import FFF.B
        import ↓EEE.A
        #if os(Linux)
        import DDD.A
        import EEE.B
        #else
        import DDD.B
        import ↓CCC
        #endif
        import AAA
        import BBB
        """):
            Example("""
            import EEE.A
            import FFF.B
            #if os(Linux)
            import DDD.A
            import EEE.B
            #else
            import CCC
            import DDD.B
            #endif
            import AAA
            import BBB
            """),
        Example("""
          @testable import BBB
        @testable import ↓AAA
        """, configuration: groupByAttributesConfiguration, excludeFromDocumentation: true):
            Example("""
            @testable import AAA
              @testable import BBB
            """),
        Example("""
          import AAA
        @testable import ↓BBB
        """, configuration: groupByAttributesConfiguration, excludeFromDocumentation: true):
            Example("""
            @testable import BBB
              import AAA
            """),
        Example("""
          import BBB
        @testable import ↓AAA
        """, configuration: groupByAttributesConfiguration, excludeFromDocumentation: true):
            Example("""
            @testable import AAA
              import BBB
            """),
        Example("""
          @testable import AAA
        @_exported import ↓BBB
        """, configuration: groupByAttributesConfiguration, excludeFromDocumentation: true):
            Example("""
            @_exported import BBB
              @testable import AAA
            """),
        Example("""
          import AAA
        @_exported @testable import ↓BBB
        """, configuration: groupByAttributesConfiguration, excludeFromDocumentation: true):
            Example("""
            @_exported @testable import BBB
              import AAA
            """)
    ]
}
