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
            Label("Display Snooze", systemImage: "display")
        }
        .menuBarExtraStyle(.menu)
    }
}
