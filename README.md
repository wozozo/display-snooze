# DisplaySnooze

A macOS menu bar app that temporarily disables external displays without unplugging them, and restores them later.

## Features

- List connected displays in the menu bar and toggle each one off/on
- **Restore All** re-enables every snoozed display
- **Quit** restores all displays before exiting
- The main display and the built-in display cannot be snoozed

## Requirements

- macOS 26 or later
- Swift 5.9+ (to build from source)

## Install

Download the `.dmg` from [Releases](https://github.com/wozozo/display-snooze/releases).

## Build from source

    ./script/build_and_run.sh

This builds `dist/DisplaySnooze.app` and launches it.

Run tests with:

    swift test

## Notes

DisplaySnooze uses the private CoreGraphics API `CGSConfigureDisplayEnabled`. Changes apply only while the app is running (`.forAppOnly`), and it may break in future macOS versions.
