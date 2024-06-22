internal struct SortedImportsRuleExamples {
    private static let groupByAttributesConfiguration = ["grouping": "attributes"]

    static let nonTriggeringExamples = [
        Example("""
        import AAA
        import BBB
        import CCC
        import DDD
        """),
        Example("""
        import Alamofire
        import API
        """),
        Example("""
        import labc
        import Ldef
        """),
        Example("""
        import BBB
        // comment
        import AAA
        import CCC
        """),
        Example("""
        @testable import AAA
        import   CCC
        """),
        Example("""
        import AAA
        @testable import   CCC
        """),
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
        """, configuration: groupByAttributesConfiguration, excludeFromDocumentation: true),
    ]

    static let triggeringExamples = [
        Example("""
        import AAA
        import ZZZ
        import ↓BBB
        import CCC
        """),
        Example("""
        import DDD
        // comment
        import CCC
        import ↓AAA
        """),
        Example("""
        @testable import CCC
        import   ↓AAA
        """),
        Example("""
        import CCC
        @testable import   ↓AAA
        """),
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
        """, configuration: groupByAttributesConfiguration, excludeFromDocumentation: true),
    ]

    static let corrections = [
        Example("""
        import AAA
        import ZZZ
        import ↓BBB
        import CCC
        """):
            Example("""
            import AAA
            import BBB
            import CCC
            import ZZZ
            """),
        Example("""
        import BBB // comment
        import ↓AAA
        """): Example("""
              import AAA
              import BBB // comment
              """),
        Example("""
        import BBB
        // comment
        import CCC
        import ↓AAA
        """):
            Example("""
            import BBB
            // comment
            import AAA
            import CCC
            """),
        Example("""
        @testable import CCC
        import  ↓AAA
        """): Example("""
              import  AAA
              @testable import CCC
              """),
        Example("""
        import CCC
        @testable import  ↓AAA
        """): Example("""
              @testable import  AAA
              import CCC
              """),
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
        """, configuration: groupByAttributesConfiguration):
            Example("""
            @testable import AAA
              @testable import BBB
            """),
        Example("""
          import AAA
        @testable import ↓BBB
        """, configuration: groupByAttributesConfiguration):
            Example("""
            @testable import BBB
              import AAA
            """),
        Example("""
          import BBB
        @testable import ↓AAA
        """, configuration: groupByAttributesConfiguration):
            Example("""
            @testable import AAA
              import BBB
            """),
        Example("""
          @testable import AAA
        @_exported import ↓BBB
        """, configuration: groupByAttributesConfiguration):
            Example("""
            @_exported import BBB
              @testable import AAA
            """),
        Example("""
          import AAA
        @_exported @testable import ↓BBB
        """, configuration: groupByAttributesConfiguration):
            Example("""
            @_exported @testable import BBB
              import AAA
            """),
    ]
}
