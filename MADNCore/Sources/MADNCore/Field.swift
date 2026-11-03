extension Game {

    public enum Field: Hashable, CaseIterable, Sendable {
        case track(Track.Field)
        case home(Player, Home.Field)
        case out(Player, Out.Field)

        public static var allCases: [Field] {
            trackFields
            + Player.allCases.flatMap { player in Home.Field.allCases.map { .home(player, $0) } }
            + Player.allCases.flatMap { player in Out.Field.allCases.map { .out(player, $0) } }
        }

        public static var trackFields: [Field] {
            (0..<Track.length).map { .track(Track.Field(wrapping: $0)) }
        }

        public var isTrack: Bool {
            if case .track = self { true } else { false }
        }

        public var owner: Player? {
            switch self {
            case .home(let player, _), .out(let player, _):
                player
            case .track(let field):
                Player.allCases.first { Track.startField(for: $0) == field }
            }
        }
    }

    public enum Out {
        public enum Field: String, CaseIterable, Sendable {
            case A, B, C, D
        }
    }

    public enum Track {
        static let length = 40

        static func startField(for player: Player) -> Field {
            Field(wrapping: player.rawValue * length / Player.allCases.count)
        }

        public struct Field: Hashable, Sendable {
            let index: Int

            init?(index: Int) {
                guard (0..<Track.length).contains(index) else { return nil }
                self.index = index
            }

            init(wrapping index: Int) {
                self.index = (index % Track.length + Track.length) % Track.length
            }
        }
    }

    public enum Home {
        public enum Field: String, CaseIterable, Sendable {
            case a, b, c, d
        }
    }
}
