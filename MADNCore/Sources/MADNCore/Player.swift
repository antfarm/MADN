extension Game {

    enum Player: Int, CaseIterable {
        case one, two, three, four

        var next: Player {
            Player.allCases[(rawValue + 1) % Player.allCases.count]
        }

        // TODO: add
        // var path: [Field]
        // func position(of field: Field) -> Int?
        // func field(at position: Int) -> Field?
    }
}
