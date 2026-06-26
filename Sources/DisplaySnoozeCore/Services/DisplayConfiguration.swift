import CoreGraphics

@_silgen_name("CGSConfigureDisplayEnabled")
func CGSConfigureDisplayEnabled(
    _ config: CGDisplayConfigRef,
    _ display: UInt32,
    _ enabled: Bool
) -> Int

public protocol DisplayConfiguring {
    func setDisplay(_ id: DisplayID, enabled: Bool) throws
}

public struct CoreGraphicsDisplayConfigurator: DisplayConfiguring {
    public init() {}

    public func setDisplay(_ id: DisplayID, enabled: Bool) throws {
        var config: CGDisplayConfigRef?
        guard CGBeginDisplayConfiguration(&config) == .success, let config else {
            throw DisplayServiceError.beginConfigurationFailed
        }

        guard CGSConfigureDisplayEnabled(config, id, enabled) == 0 else {
            CGCancelDisplayConfiguration(config)
            throw DisplayServiceError.privateAPIFailed
        }

        guard CGCompleteDisplayConfiguration(config, .forAppOnly) == .success else {
            CGCancelDisplayConfiguration(config)
            throw DisplayServiceError.completeConfigurationFailed
        }
    }
}
