internal struct StatementPositionRuleExamples {
    static let nonTriggeringExamples = [
        Example("if true {\n    foo()\n} else {\n    bar()\n}"),
        Example("if true {\n    foo\n} else if true {\n    bar()\n} else {\n    return\n}"),
        Example("do {\n    foo()\n} catch {\n    bar()\n}"),
        Example("do {\n    foo()\n} catch let error {\n    bar()\n} catch {\n    return\n}"),
        Example("struct A { let catchphrase: Int }\nlet a = A(\n catchphrase: 0\n)"),
        Example("struct A { let `catch`: Int }\nlet a = A(\n `catch`: 0\n)")
    ]

    static let triggeringExamples = [
        Example("if true {\n    foo()\n}↓else {\n    bar()\n}"),
        Example("if true {\n    foo()\n}↓    else if true {\n    bar()\n}"),
        Example("if true {\n    foo()\n}↓\nelse true {\n    bar()\n}"),
        Example("do {\n    foo()\n}↓catch {\n    bar()\n}"),
        Example("do {\n    foo()\n}↓    catch {\n    bar()\n}"),
        Example("do {\n    foo()\n}↓\ncatch {\n    bar()\n}")
    ]

    static let corrections = [
         Example("if true {\n    foo()\n}↓\nelse {\n    bar()\n}"):
             Example("if true {\n    foo()\n} else {\n    bar()\n}"),
         Example("if true {\n    foo()\n}↓   else if true {\n    bar()\n}"):
             Example("if true {\n    foo()\n} else if true {\n    bar()\n}"),
         Example("do {\n    foo()\n}↓\ncatch {\n    bar()\n}"):
             Example("do {\n    foo()\n} catch {\n    bar()\n}"),
         Example("do {\n    foo()\n}↓    catch {\n    bar()\n}"):
             Example("do {\n    foo()\n} catch {\n    bar()\n}")
     ]
 }
