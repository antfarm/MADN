extension Game {

    struct Board {
        private var pieces: Pieces = [:]

        init(pieces: Pieces? = nil) throws {
            let initialPieces = Dictionary(uniqueKeysWithValues:
                Player.allCases.flatMap { player in
                    Out.Field.allCases.map { field in (Field.out(player, field), player) }
                }
            )

            for (field, player) in pieces ?? initialPieces {
                try add(pieceFor: player, at: field)
            }
        }

        func player(at field: Field) -> Player? {
            pieces[field]
        }

        func pieces(for player: Player) -> Set<Field> {
            Set(pieces.filter { $0.value == player }.keys)
        }

        mutating func add(pieceFor player: Player, at field: Field) throws {
            guard pieces[field] == nil else {
                throw GameError(message: "\(field) is occupied")
            }

            switch field {
            case .home(let owner, _), .out(let owner, _):
                guard owner == player else {
                    throw GameError(message: "Player \(player.rawValue) cannot be on \(field)")
                }
            case .track:
                break
            }

            guard pieces(for: player).count < Out.Field.allCases.count else {
                throw GameError(message: "Player \(player.rawValue) has too many pieces")
            }

            pieces[field] = player
        }
    }

    public enum Field: Hashable, CaseIterable, Sendable {
        case track(Player, Track.Field)
        case home(Player, Home.Field)
        case out(Player, Out.Field)

        public static var allCases: [Field] {
            trackFields
            + Player.allCases.flatMap { player in Home.Field.allCases.map { .home(player, $0) } }
            + Player.allCases.flatMap { player in Out.Field.allCases.map { .out(player, $0) } }
        }

        public static var trackFields: [Field] {
            Player.allCases.flatMap { player in Track.Field.allCases.map { .track(player, $0) } }
        }

        public var isTrack: Bool {
            if case .track = self { true } else { false }
        }

        public var owner: Player? {
            switch self {
            case .home(let player, _), .out(let player, _):
                player
            case .track(let sector, _):
                self == sector.startField ? sector : nil
            }
        }
    }

    public enum Out {
        public enum Field: String, CaseIterable, Sendable {
            case A, B, C, D
        }
    }

    public enum Track {
        static let sectorLength = 10

        public struct Field: Hashable, CaseIterable, Sendable {
            let index: Int

            init?(index: Int) {
                guard (0..<Track.sectorLength).contains(index) else { return nil }
                self.index = index
            }

            public static var allCases: [Field] {
                (0..<Track.sectorLength).compactMap(Field.init(index:))
            }
        }
    }

    public enum Home {
        public enum Field: String, CaseIterable, Sendable {
            case a, b, c, d
        }
    }
}

extension Game.Player {

    func stepsTravelled(to field: Game.Field) throws -> Int {
        guard let steps = path.firstIndex(of: field) else {
            throw GameError(message: "Field not on player's path")
        }

        return steps
    }

    func field(stepsTravelled steps: Int) -> Game.Field? {
        path.indices.contains(steps) ? path[steps] : nil
    }

    var startField: Game.Field {
        field(stepsTravelled: 0)! // every path has a step 0
    }

    private var path: [Game.Field] { Self.paths[self]! }

    private static let paths: [Game.Player: [Game.Field]] = Dictionary(uniqueKeysWithValues:
        Game.Player.allCases.map { player in
            let players = sequence(first: player) { $0.next }.prefix(Game.Player.allCases.count)
            let track = players.flatMap { player in Game.Track.Field.allCases.map { Game.Field.track(player, $0) } }
            let home = Game.Home.Field.allCases.map { Game.Field.home(player, $0) }

            return (player, track + home)
        }
    )
}

/**
    1A 1B       18 19 20       2B 2A
    1C 1D       17 2a 21       2D 2C
                16 2b 22
                15 2c 23
    10 11 12 13 14 2d 24 25 26 27 28
    09 1a 1b 1c 1d    3d 3c 3b 3a 29
    08 07 06 05 04 0d 34 33 32 31 30
                03 0c 35
                02 0b 36
    0C 0D       01 0a 37       3D 3C
    0A 0B       00 39 38       3B 3A
*/

extension Game.Field: LosslessStringConvertible {

    public init?(_ description: String) {
        guard description.count == 2,
              let digit = description.first!.wholeNumberValue,
              let player = Game.Player(rawValue: digit)
        else { return nil }

        let position = description.last!

        if let index = position.wholeNumberValue, let field = Game.Track.Field(index: index) {
            self = .track(player, field)
        }
        else if let field = Game.Home.Field(rawValue: String(position)) {
            self = .home(player, field)
        }
        else if let field = Game.Out.Field(rawValue: String(position)) {
            self = .out(player, field)
        }
        else {
            return nil
        }
    }

    public var description: String {
        switch self {
        case .track(let player, let field):
            "\(player.rawValue)\(field.index)"
        case .home(let player, let field):
            "\(player.rawValue)\(field.rawValue)"
        case .out(let player, let field):
            "\(player.rawValue)\(field.rawValue)"
        }
    }
}
