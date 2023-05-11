# Releasing SwiftLint

For SwiftLint contributors, follow these steps to cut a release:

1. Come up with a witty washer- or dryer-themed release name. Past names include:
    * Tumble Dry
    * FabricSoftenerRule
    * Top Loading
    * Fresh Out Of The Dryer
1. Make sure you have the latest stable Xcode version installed and
  `xcode-select`ed
1. Release new version: `make release "0.2.0: Tumble Dry"`
1. Wait for the Docker CI job to finish then run: `make zip_linux_release`
1. Publish to Homebrew and CocoaPods trunk: `make publish`
1. Celebrate. :tada:
