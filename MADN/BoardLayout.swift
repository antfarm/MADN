import MADNCore

enum BoardLayout {

    private static let boardMap: [[Game.Field?]] = {
        let map = """
            1A 1B .. .. 18 19 20 .. .. 2B 2A
            1C 1D .. .. 17 2a 21 .. .. 2D 2C
            .. .. .. .. 16 2b 22 .. .. .. ..
            .. .. .. .. 15 2c 23 .. .. .. ..
            10 11 12 13 14 2d 24 25 26 27 28
            09 1a 1b 1c 1d .. 3d 3c 3b 3a 29
            08 07 06 05 04 0d 34 33 32 31 30
            .. .. .. .. 03 0c 35 .. .. .. ..
            .. .. .. .. 02 0b 36 .. .. .. ..
            0C 0D .. .. 01 0a 37 .. .. 3D 3C
            0A 0B .. .. 00 39 38 .. .. 3B 3A
            """
            .split(separator: "\n")
            .map { $0.split(separator: " ") }
            .map { $0.map { Game.Field(String($0)) } }

        let fields = map.joined().compactMap { $0 }

        assert(Set(fields).count == fields.count, "Duplicate fields in board map")
        assert(Set(fields) == Set(Game.Field.allCases), "Board map does not match the game's fields")

        return map
    }()

    static let cellsPerSide = boardMap.count

    static func field(row: Int, column: Int) -> Game.Field? {
        boardMap[row][column]
    }

    private static func cell(of field: Game.Field) -> (row: Int, column: Int)? {
        for (row, columns) in boardMap.enumerated() {
            if let column = columns.firstIndex(of: field) { return (row, column) }
        }
        return nil
    }

    static let trackCells = Game.Field.trackFields.compactMap { cell(of: $0) }
}
