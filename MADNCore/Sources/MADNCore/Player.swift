extension Game {

    public enum Player: Int, CaseIterable, Sendable {
        case one, two, three, four

        var next: Player {
            Player.allCases[(rawValue + 1) % Player.allCases.count]
        }

        func stepsTravelled(to field: Field) throws -> Int {
            guard let steps = path.firstIndex(of: field) else {
                throw GameError(message: "Field not on player's path")
            }

            return steps
        }

        func field(stepsTravelled steps: Int) -> Field? {
            path.indices.contains(steps) ? path[steps] : nil
        }

        var startField: Field {
            field(stepsTravelled: 0)! // every path has a step 0
        }

        private var path: [Field] { Self.paths[self]! }

        private static let paths: [Player: [Field]] = Dictionary(uniqueKeysWithValues:
            Player.allCases.map { player in
                let players = sequence(first: player) { $0.next }.prefix(Player.allCases.count)
                let track = players.flatMap { player in Track.Field.allCases.map { Field.track(player, $0) } }
                let home = Home.Field.allCases.map { Field.home(player, $0) }

                return (player, track + home)
            }
        )
    }
}
