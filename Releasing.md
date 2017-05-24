# Releasing SwiftLint

For SwiftLint contributors, follow these steps to cut a release:

1. Come up with a witty washer- or dryer-themed release name. Past names include:
    * Tumble Dry
    * FabricSoftenerRule
    * Top Loading
    * Fresh Out Of The Dryer
2. Push new version: `make push_version "0.2.0: Tumble Dry"`
3. Make sure you have the latest stable Xcode version installed and
  `xcode-select`ed.
4. Create the pkg installer, framework zip, and portable zip: `make release`
5. Create a GitHub release: https://github.com/realm/SwiftLint/releases/new
    * Specify the tag you just pushed from the dropdown.
    * Set the release title to the new version number & release name.
    * Add the changelog section to the release description text box.
    * Upload the pkg installer, framework zip, and portable zip you just built
      to the GitHub release binaries.
    * Click "Publish release".
6. Publish to Homebrew and CocoaPods trunk: `make publish`
7. Celebrate. :tada:
