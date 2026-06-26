import Combine
import Foundation

@MainActor
public final class DisplayStore: ObservableObject {
    @Published public private(set) var displays: [DisplaySnapshot] = []
    @Published public private(set) var lastError: String?

    private let discovery: DisplayDiscovering
    private let configurator: DisplayConfiguring
    private var offDisplayIDs: Set<DisplayID> = []
    private var displayNamesByID: [DisplayID: String] = [:]

    public init(
        discovery: DisplayDiscovering = CoreGraphicsDisplayDiscovery(),
        configurator: DisplayConfiguring = CoreGraphicsDisplayConfigurator()
    ) {
        self.discovery = discovery
        self.configurator = configurator
    }

    @discardableResult
    public func refresh() -> Bool {
        do {
            let activeDisplays = try discovery.activeDisplays()
            var merged = activeDisplays.map { display in
                let powerState: DisplayPowerState = offDisplayIDs.contains(display.id) ? .off : .active
                let name = displayName(for: display, powerState: powerState)

                return DisplaySnapshot(
                    id: display.id,
                    name: name,
                    isMain: display.isMain,
                    isBuiltin: display.isBuiltin,
                    powerState: powerState
                )
            }

            let activeIDs = Set(activeDisplays.map(\.id))
            for previous in displays where offDisplayIDs.contains(previous.id) && !activeIDs.contains(previous.id) {
                merged.append(
                    DisplaySnapshot(
                        id: previous.id,
                        name: previous.name,
                        isMain: discovery.isMainDisplay(previous.id),
                        isBuiltin: discovery.isBuiltinDisplay(previous.id),
                        powerState: .off
                    )
                )
            }

            displays = merged.sorted { left, right in
                if left.isMain != right.isMain {
                    return left.isMain
                }
                return left.name.localizedStandardCompare(right.name) == .orderedAscending
            }
            updateDisplayNameCache(from: merged)
            lastError = nil
            return true
        } catch {
            lastError = UserDisplayError.discoveryFailed.rawValue
            return false
        }
    }

    @discardableResult
    public func snooze(_ id: DisplayID) -> Bool {
        guard state(for: id) == .active, canSnooze(id) else {
            refresh()
            return false
        }

        let previousState = state(for: id) ?? .active
        setState(.pending, for: id)

        do {
            try configurator.setDisplay(id, enabled: false)
            cacheDisplayName(for: id)
            offDisplayIDs.insert(id)
            setState(.off, for: id)
            lastError = nil
            return true
        } catch {
            setState(previousState, for: id)
            lastError = UserDisplayError.snoozeFailed.rawValue
            return false
        }
    }

    @discardableResult
    public func wake(_ id: DisplayID) -> Bool {
        wake(id, reportRestoreFailure: false)
    }

    @discardableResult
    public func restoreAll() -> Bool {
        var didFail = false

        for id in offDisplayIDs.sorted() {
            if !wake(id, reportRestoreFailure: true) {
                didFail = true
            }
        }

        if didFail {
            lastError = UserDisplayError.restoreFailed.rawValue
        }
        return !didFail
    }

    public func clearError() {
        lastError = nil
    }

    private func wake(_ id: DisplayID, reportRestoreFailure: Bool) -> Bool {
        guard offDisplayIDs.contains(id) else {
            return false
        }

        let previousState = state(for: id) ?? .off
        setState(.pending, for: id)

        do {
            try configurator.setDisplay(id, enabled: true)
            offDisplayIDs.remove(id)
            refresh()
            lastError = nil
            return true
        } catch {
            setState(previousState, for: id)
            lastError = reportRestoreFailure
                ? UserDisplayError.restoreFailed.rawValue
                : UserDisplayError.wakeFailed.rawValue
            return false
        }
    }

    private func canSnooze(_ id: DisplayID) -> Bool {
        !discovery.isMainDisplay(id) && !discovery.isBuiltinDisplay(id)
    }

    private func state(for id: DisplayID) -> DisplayPowerState? {
        displays.first { $0.id == id }?.powerState
    }

    private func setState(_ state: DisplayPowerState, for id: DisplayID) {
        guard let index = displays.firstIndex(where: { $0.id == id }) else {
            return
        }
        displays[index].powerState = state
    }

    private func displayName(
        for display: DiscoveredDisplay,
        powerState: DisplayPowerState
    ) -> String {
        if powerState == .off, let cachedName = displayNamesByID[display.id] {
            return cachedName
        }

        if isFallbackName(display.name, for: display.id),
           let cachedName = displayNamesByID[display.id],
           !isFallbackName(cachedName, for: display.id) {
            return cachedName
        }

        return display.name
    }

    private func updateDisplayNameCache(from displays: [DisplaySnapshot]) {
        for display in displays where !isFallbackName(display.name, for: display.id) {
            displayNamesByID[display.id] = display.name
        }
    }

    private func cacheDisplayName(for id: DisplayID) {
        guard let display = displays.first(where: { $0.id == id }),
              !isFallbackName(display.name, for: id) else {
            return
        }
        displayNamesByID[id] = display.name
    }

    private func isFallbackName(_ name: String, for id: DisplayID) -> Bool {
        name == "Display \(id)"
    }
}
