extension Game {

    public static func isValid(fields: Set<String>) -> Bool {
        fields == Set(Field.allCases.map(\.description))
    }

    public init(pieces: [Set<String>], player: Player = .one) {
        self.init(pieces: Dictionary(uniqueKeysWithValues:
            zip(Player.allCases, pieces).flatMap { player, fields in
                fields.map { (Field($0)!, player) }
            }
        ), player: player)
    }

    public func piece(at field: String) -> Int? {
        guard let field = Field(field) else { return nil }

        return piece(at: field)?.rawValue
    }

    public func movablePieces() -> Set<String> {
        let movable: Set<Field> = movablePieces()

        return Set(movable.map(\.description))
    }

    public mutating func move(field: String) throws {
        guard let field = Field(field) else { throw GameError(message: "Invalid field") }

        try move(field: field)
    }
}
