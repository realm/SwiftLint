# Releasing SwiftLint

For SwiftLint contributors, follow these steps to cut a release:

1. Come up with a witty washer- or dryer-themed release name. Past names include:
    * Tumble Dry
    * FabricSoftenerRule
    * Top Loading
    * Fresh Out Of The Dryer
1. Make sure you have the latest stable Xcode version installed and `xcode-select`ed.
1. Make sure that the selected Xcode has the latest SDKs of all supported platforms installed. This is required to
   build the CocoaPods release.
1. Release a new version by running `make release "0.2.0: Tumble Dry"`.
1. Celebrate. :tada:
