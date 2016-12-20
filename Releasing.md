# Releasing SwiftLint

For SwiftLint contributors, follow these steps to cut a release:

1. Update version number: `make set_version 0.2.0`
2. Come up with a witty washer- or dryer-themed release name. Past names include:
    * Tumble Dry
    * FabricSoftenerRule
    * Top Loading
    * Fresh Out Of The Dryer
3. Update the first header in `CHANGELOG.md` to the new version number & release
   name.
4. Commit & push to the `master` branch.
5. Tag: `git tag -a 0.2.0 -m "0.2.0: Tumble Dry"; git push origin 0.2.0`
6. Make sure you have the latest stable Xcode version installed and
  `xcode-select`ed.
7. Create the pkg installer, framework zip, and portable zip: `make release`
8. Create a GitHub release: https://github.com/realm/SwiftLint/releases/new
    * Specify the tag you just pushed from the dropdown.
    * Set the release title to the new version number & release name.
    * Add the changelog section to the release description text box.
    * Upload the pkg installer, framework zip, and portable zip you just built
      to the GitHub release binaries.
    * Click "Publish release".
9. Publish to Homebrew and CocoaPods trunk: `make publish`
10. Celebrate. :tada:
