# Run Ice Time in an iPhone simulator on your Mac

This is a local testing setup. It does not upload to Apple, publish the game, or require banking information. The iOS app uses the existing HTML/CSS/JavaScript through Capacitor, not React Native or Expo.

## 1. Install the Mac tools (once)

- Install **Xcode 26 or newer** from the Mac App Store: https://apps.apple.com/app/xcode/id497799835. Your macOS version must support that Xcode version.
- Open Xcode once, accept its license, and allow the initial components to install.
- In **Xcode > Settings > Components** (called **Platforms** in some versions), download an iOS simulator runtime if none is installed.
- Install **Node.js 22 or newer**: https://nodejs.org/en/download. Check in Terminal with `node --version`.
- If Xcode cannot find its tools, run `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer` on your Mac.

No Expo account is needed for this Capacitor project. Running a simulator does not require configuring an Apple signing team.

## 2. Get the preparation branch

Open Terminal and run these commands for a fresh checkout:

```sh
git clone --branch mobile/capacitor-ios-prep https://github.com/Pythonidaer/calling-for-testcliff.git
cd calling-for-testcliff
npm ci
npm run ios:setup
npm run ios:open
```

If you already have this repository on your Mac, save any local work first, then use `git fetch origin` and `git switch mobile/capacitor-ios-prep` in that existing checkout instead of cloning again.

`ios:setup` bundles the web files and adds the iOS project if missing, or syncs it if it already exists. This project uses Apple's Swift Package Manager; CocoaPods is not needed.

## 3. Press Play in Xcode

1. Wait for Xcode to finish resolving its Swift packages (internet required for the initial setup).
2. Select the **App** scheme in the top toolbar.
3. Select an **iPhone simulator** beside it, rather than “Any iOS Device” or your physical phone.
4. Click the **triangle Play button**, or press **Command + R**.
5. The simulator launches and opens Ice Time.

If no iPhone is listed, install an iOS runtime in Xcode Settings and create a simulator in **Window > Devices and Simulators > Simulators > +**.

## After changing the game

Run `npm run ios:sync` and press Command + R in Xcode again. This copies the latest game and bundled roster snapshot into the native project.

## Quick testing checklist

- [ ] Game loads and all 26 letters respond.
- [ ] Decade and team filters start a new round.
- [ ] Winning and losing reveal the team and position.
- [ ] Scores remain after closing and reopening the app.
- [ ] No speaker button or sounds appear.
- [ ] Content stays clear of the notch and home indicator, including landscape.
- [ ] Gameplay works without internet after installation (roster data is bundled).

Safari/website scores are separate from simulator/native-app scores. “Current roster” means the snapshot bundled when the app was built; the website's daily refresh does not update an installed native app. Rebuild/sync to include a newer snapshot.

## What is deferred

This is a development project, not a release-ready App Store submission. App artwork, release signing, final bundle ID, privacy/store metadata, TestFlight distribution, and payments can come later. `com.pythonidaer.icetime` is a development identifier; no Apple app record has been registered. There is no automatic Apple submission workflow.

A TestFlight beta eventually requires an App Store Connect app record and a signed build uploaded to Apple. Publishing publicly is a separate step.

## Verification limits

The game tests, web packaging, and browser checks can run on Linux. Actual Xcode compilation and simulator behavior must be checked on a Mac. If a step fails, share the exact error and your macOS/Xcode versions.

Official documentation:
- https://capacitorjs.com/docs/ios
- https://capacitorjs.com/docs/ios/spm
- https://capacitorjs.com/docs/getting-started/environment-setup
