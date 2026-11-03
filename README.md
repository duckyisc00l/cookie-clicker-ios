# Cookie Clicker for iOS (personal use)

A Swift iPhone app that runs the Cookie Clicker mobile game (v8, ad-less) taken from the Android APK.

- `CookieClicker/www/`: the game's files, unchanged from the APK
- `CookieClicker/*.swift`: the iOS app. It runs the game in a full-screen web view and handles saving, save export/import and links in Swift, where the Android version used Cordova plugins.

## Getting the IPA
Every push to `main` builds an unsigned IPA on GitHub Actions. Download it from **Releases** and install it with Sideloadly or AltStore.

Cookie Clicker is © Orteil / DashNet. Keep this repo private.
