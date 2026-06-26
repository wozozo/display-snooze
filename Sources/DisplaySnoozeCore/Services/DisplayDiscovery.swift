import AppKit
import CoreGraphics

public protocol DisplayDiscovering {
    func activeDisplays() throws -> [DiscoveredDisplay]
    func isMainDisplay(_ id: DisplayID) -> Bool
    func isBuiltinDisplay(_ id: DisplayID) -> Bool
}

public struct CoreGraphicsDisplayDiscovery: DisplayDiscovering {
    public init() {}

    public func activeDisplays() throws -> [DiscoveredDisplay] {
        var count: UInt32 = 0
        guard CGGetActiveDisplayList(0, nil, &count) == .success else {
            throw DisplayServiceError.discoveryFailed
        }

        var ids = [CGDirectDisplayID](repeating: 0, count: Int(count))
        guard CGGetActiveDisplayList(count, &ids, &count) == .success else {
            throw DisplayServiceError.discoveryFailed
        }

        return ids.prefix(Int(count)).map { id in
            DiscoveredDisplay(
                id: id,
                name: displayName(for: id),
                isMain: isMainDisplay(id),
                isBuiltin: isBuiltinDisplay(id)
            )
        }
    }

    public func isMainDisplay(_ id: DisplayID) -> Bool {
        id == CGMainDisplayID()
    }

    public func isBuiltinDisplay(_ id: DisplayID) -> Bool {
        CGDisplayIsBuiltin(id) != 0
    }

    private func displayName(for id: DisplayID) -> String {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        let screen = NSScreen.screens.first { screen in
            guard let number = screen.deviceDescription[key] as? NSNumber else {
                return false
            }
            return number.uint32Value == id
        }

        return screen?.localizedName ?? "Display \(id)"
    }
}
