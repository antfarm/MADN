extension Game {

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
