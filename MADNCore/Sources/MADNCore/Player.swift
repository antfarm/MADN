extension Game {

    enum Player: Int, CaseIterable {
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

        private var path: [Field] { Self.paths[self]! }

        private static let paths: [Player: [Field]] = Dictionary(uniqueKeysWithValues:
            Player.allCases.map { player in
                let circle = (0..<Track.length).map { Field.track(Track.Field(wrapping: $0)) }
                let start = Track.startField(for: player).index
                let home = Home.Field.allCases.map { Field.home(player, $0) }

                return (player, Array(circle[start...] + circle[..<start]) + home)
            }
        )
    }
}
