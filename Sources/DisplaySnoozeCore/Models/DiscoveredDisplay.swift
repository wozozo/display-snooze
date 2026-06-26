public struct DiscoveredDisplay: Equatable {
    public let id: DisplayID
    public let name: String
    public let isMain: Bool
    public let isBuiltin: Bool

    public init(id: DisplayID, name: String, isMain: Bool, isBuiltin: Bool) {
        self.id = id
        self.name = name
        self.isMain = isMain
        self.isBuiltin = isBuiltin
    }
}
