import Foundation

public typealias DisplayID = UInt32

public enum DisplayPowerState: Equatable {
    case active
    case off
    case pending
}

public struct DisplaySnapshot: Identifiable, Equatable {
    public let id: DisplayID
    public var name: String
    public var isMain: Bool
    public var isBuiltin: Bool
    public var powerState: DisplayPowerState

    public var isControllable: Bool {
        !isMain && !isBuiltin
    }

    public var disabledReason: String? {
        if isMain {
            return "Main display"
        }
        if isBuiltin {
            return "Built-in display"
        }
        return nil
    }

    public init(
        id: DisplayID,
        name: String,
        isMain: Bool,
        isBuiltin: Bool,
        powerState: DisplayPowerState
    ) {
        self.id = id
        self.name = name
        self.isMain = isMain
        self.isBuiltin = isBuiltin
        self.powerState = powerState
    }
}
