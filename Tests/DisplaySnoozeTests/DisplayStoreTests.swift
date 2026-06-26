import XCTest
@testable import DisplaySnoozeCore

@MainActor
final class DisplayStoreTests: XCTestCase {
    func testMainDisplayCannotBeSnoozed() {
        let discovery = MockDiscovery(
            active: [display(1, isMain: true)],
            mainID: 1
        )
        let configurator = MockConfigurator()
        let store = DisplayStore(discovery: discovery, configurator: configurator)

        XCTAssertTrue(store.refresh())
        XCTAssertFalse(store.snooze(1))
        XCTAssertTrue(configurator.calls.isEmpty)
        XCTAssertEqual(store.displays.first?.powerState, .active)
    }

    func testBuiltinDisplayCannotBeSnoozed() {
        let discovery = MockDiscovery(
            active: [display(1, isBuiltin: true)],
            builtinIDs: [1]
        )
        let configurator = MockConfigurator()
        let store = DisplayStore(discovery: discovery, configurator: configurator)

        XCTAssertTrue(store.refresh())
        XCTAssertFalse(store.snooze(1))
        XCTAssertTrue(configurator.calls.isEmpty)
        XCTAssertEqual(store.displays.first?.powerState, .active)
    }

    func testExternalDisplayCanBeSnoozed() {
        let discovery = MockDiscovery(active: [display(2)])
        let configurator = MockConfigurator()
        let store = DisplayStore(discovery: discovery, configurator: configurator)

        XCTAssertTrue(store.refresh())
        XCTAssertTrue(store.snooze(2))

        XCTAssertEqual(configurator.calls, [.init(id: 2, enabled: false)])
        XCTAssertEqual(store.displays.first?.powerState, .off)
    }

    func testOffDisplayRemainsAfterRefreshWhenNoLongerActive() {
        let discovery = MockDiscovery(active: [display(2)])
        let store = DisplayStore(discovery: discovery, configurator: MockConfigurator())

        XCTAssertTrue(store.refresh())
        XCTAssertTrue(store.snooze(2))

        discovery.active = []
        XCTAssertTrue(store.refresh())

        XCTAssertEqual(store.displays.map(\.id), [2])
        XCTAssertEqual(store.displays.first?.powerState, .off)
    }

    func testOffDisplayKeepsKnownNameWhenDiscoveryFallsBackToDisplayIDName() {
        let discovery = MockDiscovery(active: [display(3, name: "DELL S2725QC")])
        let store = DisplayStore(discovery: discovery, configurator: MockConfigurator())

        XCTAssertTrue(store.refresh())
        XCTAssertTrue(store.snooze(3))

        discovery.active = [display(3)]
        XCTAssertTrue(store.refresh())

        XCTAssertEqual(store.displays.first?.name, "DELL S2725QC")
        XCTAssertEqual(store.displays.first?.powerState, .off)
    }

    func testActiveDisplayNameUpdatesWhenDiscoveryProvidesRealName() {
        let discovery = MockDiscovery(active: [display(3, name: "DELL S2725QC")])
        let store = DisplayStore(discovery: discovery, configurator: MockConfigurator())

        XCTAssertTrue(store.refresh())

        discovery.active = [display(3, name: "DELL S2725QC (USB-C)")]
        XCTAssertTrue(store.refresh())

        XCTAssertEqual(store.displays.first?.name, "DELL S2725QC (USB-C)")
        XCTAssertEqual(store.displays.first?.powerState, .active)
    }

    func testSnoozeFailureDoesNotLeavePendingState() {
        let discovery = MockDiscovery(active: [display(2)])
        let configurator = MockConfigurator(failDisableIDs: [2])
        let store = DisplayStore(discovery: discovery, configurator: configurator)

        XCTAssertTrue(store.refresh())
        XCTAssertFalse(store.snooze(2))

        XCTAssertEqual(store.displays.first?.powerState, .active)
        XCTAssertEqual(store.lastError, UserDisplayError.snoozeFailed.rawValue)
    }

    func testRestoreAllContinuesAfterFailure() {
        let discovery = MockDiscovery(active: [display(2), display(3)])
        let configurator = MockConfigurator(failEnableIDs: [2])
        let store = DisplayStore(discovery: discovery, configurator: configurator)

        XCTAssertTrue(store.refresh())
        XCTAssertTrue(store.snooze(2))
        XCTAssertTrue(store.snooze(3))

        XCTAssertFalse(store.restoreAll())

        XCTAssertTrue(configurator.calls.contains(.init(id: 2, enabled: true)))
        XCTAssertTrue(configurator.calls.contains(.init(id: 3, enabled: true)))
        XCTAssertEqual(store.displays.first { $0.id == 2 }?.powerState, .off)
        XCTAssertEqual(store.displays.first { $0.id == 3 }?.powerState, .active)
        XCTAssertEqual(store.lastError, UserDisplayError.restoreFailed.rawValue)
    }
}

private func display(
    _ id: DisplayID,
    name: String? = nil,
    isMain: Bool = false,
    isBuiltin: Bool = false
) -> DiscoveredDisplay {
    DiscoveredDisplay(
        id: id,
        name: name ?? "Display \(id)",
        isMain: isMain,
        isBuiltin: isBuiltin
    )
}

private final class MockDiscovery: DisplayDiscovering {
    var active: [DiscoveredDisplay]
    var mainID: DisplayID
    var builtinIDs: Set<DisplayID>

    init(
        active: [DiscoveredDisplay],
        mainID: DisplayID = 0,
        builtinIDs: Set<DisplayID> = []
    ) {
        self.active = active
        self.mainID = mainID
        self.builtinIDs = builtinIDs
    }

    func activeDisplays() throws -> [DiscoveredDisplay] {
        active
    }

    func isMainDisplay(_ id: DisplayID) -> Bool {
        id == mainID
    }

    func isBuiltinDisplay(_ id: DisplayID) -> Bool {
        builtinIDs.contains(id)
    }
}

private struct ConfigurationCall: Equatable {
    let id: DisplayID
    let enabled: Bool
}

private final class MockConfigurator: DisplayConfiguring {
    var calls: [ConfigurationCall] = []
    let failDisableIDs: Set<DisplayID>
    let failEnableIDs: Set<DisplayID>

    init(
        failDisableIDs: Set<DisplayID> = [],
        failEnableIDs: Set<DisplayID> = []
    ) {
        self.failDisableIDs = failDisableIDs
        self.failEnableIDs = failEnableIDs
    }

    func setDisplay(_ id: DisplayID, enabled: Bool) throws {
        calls.append(.init(id: id, enabled: enabled))

        if enabled, failEnableIDs.contains(id) {
            throw DisplayServiceError.privateAPIFailed
        }

        if !enabled, failDisableIDs.contains(id) {
            throw DisplayServiceError.privateAPIFailed
        }
    }
}
