import AppKit
import DisplaySnoozeCore
import SwiftUI

@main
struct DisplaySnoozeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = DisplayStore()

    var body: some Scene {
        MenuBarExtra {
            DisplayMenuView(store: store)
                .onAppear {
                    appDelegate.store = store
                    store.refresh()
                }
        } label: {
            Image(nsImage: MenuBarIconImage.image)
                .accessibilityLabel("Display Snooze")
        }
        .menuBarExtraStyle(.menu)
    }
}

private enum MenuBarIconImage {
    static var image: NSImage {
        guard let url = Bundle.module.url(forResource: "MenuBarIcon", withExtension: "png"),
              let source = NSImage(contentsOf: url) else {
            return NSImage(systemSymbolName: "display", accessibilityDescription: "Display Snooze") ?? NSImage()
        }
        let image = NSImage(size: NSSize(width: 18, height: 16))
        image.lockFocus()
        source.draw(
            in: NSRect(x: 0, y: -1, width: 18, height: 16),
            from: .zero,
            operation: .sourceOver,
            fraction: 1
        )
        image.unlockFocus()
        image.size = NSSize(width: 18, height: 16)
        image.isTemplate = true
        return image
    }
}
