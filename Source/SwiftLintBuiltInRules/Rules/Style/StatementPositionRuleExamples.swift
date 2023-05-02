internal struct StatementPositionRuleExamples {
    static func nonTriggeringExamples(_ modeConfiguration: StatementMode) -> [Example] {
        switch modeConfiguration {
        case .default:
            return [
                Example("if true {\n    foo()\n} else {\n    bar()\n}"),
                Example("if true {\n    foo\n} else if true {\n    bar()\n} else {\n    return\n}"),
                Example("do {\n    foo()\n} catch {\n    bar()\n}"),
                Example("do {\n    foo()\n} catch let error {\n    bar()\n} catch {\n    return\n}"),
                Example("struct A { let catchphrase: Int }\nlet a = A(\n catchphrase: 0\n)"),
                Example("struct A { let `catch`: Int }\nlet a = A(\n `catch`: 0\n)")
            ]
        case .uncuddledElse:
            return [
                Example("if true {\n    foo()\n}\nelse {\n    bar()\n}"),
                Example("if true {\n    foo()\n}\nelse if true {\n    bar()\n}\nelse {\n    return\n}"),
                Example("if true { foo() }\nelse { bar() }"),
                Example("if true { foo() }\nelse if true { bar() }\nelse { return }"),
                Example("do {\n    foo()\n}\ncatch {\n    bar()\n}"),
                Example("do {\n    foo()\n}\ncatch {\n    bar()\n}\ncatch {\n    return\n}"),
                Example("do { foo() }\ncatch { bar() }"),
                Example("do { foo() }\ncatch { bar() }\ncatch { return }")
            ]
        }
    }

    static func triggeringExamples(_ modeConfiguration: StatementMode) -> [Example] {
        switch modeConfiguration {
        case .default:
            return [
                Example("if true {\n    foo()\n}↓else {\n    bar()\n}"),
                Example("if true {\n    foo()\n}↓    else if true {\n    bar()\n}"),
                Example("if true {\n    foo()\n}↓\nelse true {\n    bar()\n}"),
                Example("do {\n    foo()\n}↓catch {\n    bar()\n}"),
                Example("do {\n    foo()\n}↓    catch {\n    bar()\n}"),
                Example("do {\n    foo()\n}↓\ncatch {\n    bar()\n}")
            ]
        case .uncuddledElse:
            return [
                Example("if true {\n    foo()\n}↓ else {\n    bar()\n}"),
                Example("if true {\n    foo()\n}↓ else if true {\n    bar()\n}↓ else {\n    return\n}"),
                Example("if true {\n    foo()\n}↓\n    else {\n    bar()\n}"),
                Example("do {\n    foo()\n}↓ catch {\n    bar()\n}"),
                Example("do {\n    foo()\n}↓ catch let error {\n    bar()\n}↓ catch {\n    return\n}"),
                Example("do {\n    foo()\n}↓\n    catch {\n    bar()\n}")
            ]
        }
    }

    static func corrections(_ configuration: StatementMode) -> [Example: Example] {
         switch configuration {
         case .default:
             return [
                 Example("if true {\n    foo()\n}↓\nelse {\n    bar()\n}"):
                     Example("if true {\n    foo()\n} else {\n    bar()\n}"),
                 Example("if true {\n    foo()\n}↓   else if true {\n    bar()\n}"):
                     Example("if true {\n    foo()\n} else if true {\n    bar()\n}"),
                 Example("do {\n    foo()\n}↓\ncatch {\n    bar()\n}"):
                     Example("do {\n    foo()\n} catch {\n    bar()\n}"),
                 Example("do {\n    foo()\n}↓    catch {\n    bar()\n}"):
                     Example("do {\n    foo()\n} catch {\n    bar()\n}")
             ]
         case .uncuddledElse:
             return [
                 Example("if true {\n    foo()\n}↓\n    else {\n    bar()\n}"):
                     Example("if true {\n    foo()\n}\nelse {\n    bar()\n}"),
                 Example("if true {\n    foo()\n}↓ else if true {\n    bar()\n}↓ else {\n    bar()\n}"):
                     Example("if true {\n    foo()\n}\nelse if true {\n    bar()\n}\nelse {\n    bar()\n}"),
                 Example("  if true {\n    foo()\n  }↓\nelse if true {\n    bar()\n  }"):
                     Example("  if true {\n    foo()\n  }\n  else if true {\n    bar()\n  }"),
                 Example("do {\n    foo()\n}↓ catch {\n    bar()\n}"):
                     Example("do {\n    foo()\n}\ncatch {\n    bar()\n}"),
                 Example("do {\n    foo()\n}↓\n    catch {\n    bar()\n}"):
                     Example("do {\n    foo()\n}\ncatch {\n    bar()\n}"),
                 Example("  do {\n    foo()\n  }↓\ncatch {\n    bar()\n  }"):
                     Example("  do {\n    foo()\n  }\n  catch {\n    bar()\n  }")
             ]
         }
     }
 }
