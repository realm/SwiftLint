## Master

##### Breaking

* The `Rule` and `ASTRule` protocol members are now non-static.  
  [aarondaub](https://github.com/aarondaub)

* Split `Rule` into `Rule` and `ParameterizedRule` protocols.  
  [aarondaub](https://github.com/aarondaub)
  [#21](https://github.com/realm/SwiftLint/issues/21)

##### Enhancements

* The following rules now conform to `ASTRule`: 
  FunctionBodyLength, Nesting, TypeBodyLength, TypeName, VariableName.  
  [JP Simard](https://github.com/jpsim)

* Add RuleEnabler, a struct that controls which rules are enabled and which are disabled.
  [Aaron Daub](https://github.com/aarondaub)

##### Bug Fixes

None.


## 0.1.0


First Version!
