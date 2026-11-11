import SwiftUI
import MADNCore

struct GameView: View {

    private enum Step {
        case selectPlayers
        case selectStartingPlayer(players: Set<Game.Player>)
        case playing
    }

    @State private var game = GameViewModel()
    @State private var step = Step.selectPlayers

    var body: some View {
        switch step {
        case .selectPlayers:
            PlayerDialog(title: "Who plays?", buttonTitle: "OK",
                         players: Game.Player.allCases, color: game.color(for:),
                         minCount: 2, maxCount: nil, selected: Set(Game.Player.allCases)) {
                step = .selectStartingPlayer(players: $0)
            }
        case .selectStartingPlayer(let players):
            let chosenPlayers = Game.Player.allCases.filter(players.contains)

            PlayerDialog(title: "Who goes first?", buttonTitle: "OK",
                         players: chosenPlayers, color: game.color(for:),
                         minCount: 1, maxCount: 1, selected: [chosenPlayers.first!]) {
                game.start(players: players, player: $0.first!)
                step = .playing
            }
        case .playing:
            BoardView(game: game)
                .disabled(game.shouldOfferNewGame)
                .overlay {
                    if game.shouldOfferNewGame {
                        if !game.isGameOver {
                            Dialog(title: "New Game?", buttons: [("OK", { step = .selectPlayers }), ("Continue", { game.continueGame() })]) {}
                        }
                        else {
                            Dialog(title: "New Game?", buttons: [("OK", { step = .selectPlayers })]) {}
                        }
                    }
                }
        }
    }
}

struct Dialog<Content: View>: View {
    let title: String
    let buttons: [(title: String, action: () -> Void)]
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 24) {
            Text(title)
                .font(.title)

            content

            HStack(spacing: 24) {
                ForEach(buttons.indices, id: \.self) { index in
                    Button(buttons[index].title, action: buttons[index].action)
                        .font(.title)
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .frame(minWidth: 320)
        .padding(32)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
    }
}

struct PlayerDialog: View {
    let title: String
    let buttonTitle: String
    let players: [Game.Player]
    let color: (Game.Player) -> Color
    let minCount: Int
    let maxCount: Int?

    @State var selected: Set<Game.Player>

    let onOK: (Set<Game.Player>) -> Void

    var body: some View {
        Dialog(title: title, buttons: [(buttonTitle, { onOK(selected) })]) {
            HStack {
                ForEach(players, id: \.self) { player in
                    PlayerButton(color: color(player), isSelected: selected.contains(player), onTap: { tap(player) })
                        .frame(width: 100, height: 100)
                }
            }
        }
    }

    private func tap(_ player: Game.Player) {
        if selected.contains(player) {
            if selected.count > minCount { selected.remove(player) }
        }
        else if maxCount == 1 {
            selected = [player]
        }
        else if selected.count < maxCount ?? players.count {
            selected.insert(player)
        }
    }
}

struct PlayerButton: View {
    let color: Color
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Circle()
                .fill(color)
                .strokeBorder(isSelected ? Color.orange : .black, lineWidth: isSelected ? 14 : 4)
                .scaleEffect(0.75)
        }
        .buttonStyle(UnstyledButtonStyle())
    }
}

struct UnstyledButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label // no pressed or disabled styling
    }
}

#Preview {
    GameView()
}

#Preview("Select players") {
    let game = GameViewModel()

    PlayerDialog(title: "Who plays?", buttonTitle: "OK", players: Game.Player.allCases, color: game.color(for:), minCount: 2, maxCount: nil, selected: Set(Game.Player.allCases)) { _ in }
}

#Preview("Select starting player") {
    let game = GameViewModel()

    PlayerDialog(title: "Who starts?", buttonTitle: "OK", players: [.one, .three, .four], color: game.color(for:), minCount: 1, maxCount: 1, selected: [.one]) { _ in }
}

#Preview("Player finished") {
    Dialog(title: "New Game?", buttons: [("OK", {}), ("Continue", {})]) {}
}

#Preview("Game over") {
    Dialog(title: "New Game?", buttons: [("OK", {})]) {}
}
