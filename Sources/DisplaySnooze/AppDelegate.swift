import AppKit
import DisplaySnoozeCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var store: DisplayStore?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        store?.restoreAll()
        return .terminateNow
    }
}
