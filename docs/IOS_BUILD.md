# iOS build (WWNGO)

Bundle ID: `com.wwngo.app` · Minimum iOS: **16.0** (Sumsub SDK)

## 1. One-time setup

1. **Xcode** (latest stable) and **Apple Developer** membership.
2. Register bundle ID `com.wwngo.app` in [App Store Connect](https://appstoreconnect.apple.com) / Certificates, Identifiers & Profiles.
3. Enable capabilities on that App ID: **Push Notifications**, **Near Field Communication Tag Reading**, **Apple Pay** (if using Stripe Payment Sheet).
4. **Firebase iOS app** with the same bundle ID:
   - Download `GoogleService-Info.plist` → place in `ios/Runner/` and add to the Runner target in Xcode.
   - Add to `dart_defines.json` (gitignored):

     ```json
     {
       "GOOGLE_MAPS_API_KEY": "...",
       "FIREBASE_IOS_APP_ID": "1:707811310736:ios:YOUR_IOS_APP_ID"
     }
     ```

5. Open **`ios/Runner.xcworkspace`** (not `.xcodeproj`), Runner target → **Signing & Capabilities** → select your **Team**, enable automatic signing.

## 2. Install pods

If `pod install` fails with a corrupt Firebase `NOTICES` file:

```bash
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
```

## 3. Build from CLI

**Simulator / unsigned device compile check:**

```bash
flutter pub get
flutter build ios --release --no-codesign --dart-define-from-file=dart_defines.json
```

Output: `build/ios/iphoneos/Runner.app`

**TestFlight / App Store (signed IPA):**

Set the active `version:` in `pubspec.yaml` (iOS block), then:

```bash
flutter build ipa --release --dart-define-from-file=dart_defines.json
```

For a different platform version, use `--build-name` and `--build-number` on the command line, or swap which `version:` line is active in `pubspec.yaml`.

Requires valid signing in Xcode (team + distribution certificate). Export options: `build/ios/ipa/`.

**Run on a connected iPhone:**

```bash
flutter run --release --dart-define-from-file=dart_defines.json
```

## 4. Archive in Xcode (alternative)

1. Open `ios/Runner.xcworkspace`.
2. Scheme **Runner**, destination **Any iOS Device**.
3. **Product → Archive** → Distribute App.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Corrupt `Pods/Firebase/.../NOTICES` | Delete `ios/Pods` and `Podfile.lock`, run `pod install` again. |
| Push not working on iOS | `FIREBASE_IOS_APP_ID` in dart-defines, `GoogleService-Info.plist` in Runner, Push capability + APNs key in Firebase. |
| NFC not working | NFC Tag Reading capability on App ID; entitlements in `Runner*.entitlements`. |
| Signing errors | Set Development Team in Xcode; bundle ID must match the portal. |
| `Build input file cannot be found: …mobileprovision` | Stale provisioning profile UUID. Runner uses **Automatic** signing in `project.pbxproj`. In Xcode: **Product → Clean Build Folder**, quit Xcode, delete Derived Data for Runner, **Settings → Accounts → [Team] → Download Manual Profiles**, reopen project, toggle **Automatically manage signing** off then on. |