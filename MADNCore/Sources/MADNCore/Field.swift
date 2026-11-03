extension Game {

    enum Field: Hashable, CaseIterable {
        case track(Track.Field)
        case home(Player, Home.Field)
        case out(Player, Out.Field)

        static var allCases: [Field] {
            (0..<Track.length).map { .track(Track.Field(wrapping: $0)) }
            + Player.allCases.flatMap { player in Home.Field.allCases.map { .home(player, $0) } }
            + Player.allCases.flatMap { player in Out.Field.allCases.map { .out(player, $0) } }
        }
    }

    enum Out {
        enum Field: String, CaseIterable {
            case A, B, C, D
        }
    }

    enum Track {
        static let length = 40

        static func startField(for player: Player) -> Field {
            Field(wrapping: player.rawValue * length / Player.allCases.count)
        }

        struct Field: Hashable {
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

    enum Home {
        enum Field: String, CaseIterable {
            case a, b, c, d
        }
    }
}
