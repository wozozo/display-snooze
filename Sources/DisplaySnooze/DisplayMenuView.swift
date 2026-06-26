import AppKit
import DisplaySnoozeCore
import SwiftUI

struct DisplayMenuView: View {
    @ObservedObject var store: DisplayStore

    var body: some View {
        ForEach(store.displays) { display in
            menuItem(for: display)
        }

        if store.displays.isEmpty {
            Text("No displays")
        }

        Divider()

        Button("Restore All") {
            store.restoreAll()
        }
        .disabled(!store.displays.contains { $0.powerState == .off })

        Button("Refresh") {
            store.refresh()
        }

        if let lastError = store.lastError {
            Divider()
            Text(lastError)
            Button("Dismiss Error") {
                store.clearError()
            }
        }

        Divider()

        Button("Quit") {
            store.restoreAll()
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }

    @ViewBuilder
    private func menuItem(for display: DisplaySnapshot) -> some View {
        switch display.powerState {
        case .active:
            if display.isControllable {
                Toggle(shortName(display.name), isOn: binding(for: display))
            } else {
                Toggle(
                    "\(shortName(display.name)) - \(display.disabledReason ?? "Unavailable")",
                    isOn: .constant(true)
                )
                .disabled(true)
            }
        case .off:
            Toggle(shortName(display.name), isOn: binding(for: display))
        case .pending:
            Toggle("\(shortName(display.name)) - Pending", isOn: .constant(false))
                .disabled(true)
        }
    }

    private func binding(for display: DisplaySnapshot) -> Binding<Bool> {
        Binding(
            get: {
                display.powerState == .active
            },
            set: { isOn in
                if isOn {
                    store.wake(display.id)
                } else {
                    store.snooze(display.id)
                }
            }
        )
    }

    private func shortName(_ name: String) -> String {
        guard name.count > 24 else {
            return name
        }
        return String(name.prefix(21)) + "..."
    }
}
