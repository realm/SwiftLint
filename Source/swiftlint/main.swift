//
//  main.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Commandant

let registry = CommandRegistry<()>()
registry.register(LintCommand())
registry.register(VersionCommand())
registry.register(HelpCommand(registry: registry))
registry.register(ExplainCommand())

registry.main(defaultVerb: "lint") { error in
    fputs("\(error)\n", stderr)
}
