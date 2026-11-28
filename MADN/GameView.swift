import SwiftUI
import MADNCore

struct GameView: View {

    private enum Step {
        case selectPlayers
        case selectStartingPlayer
        case playing
    }

    @State private var game: GameViewModel

    @State private var step: Step

    @State private var isQuitting = false

    init(game: Game? = nil) {
        self.game = GameViewModel(game: game ?? (try! Game()))
        step = game == nil ? .selectPlayers : .playing
    }

    var body: some View {
        BoardView(game: game, hidesDie: step == .selectPlayers)
            .disabled(step != .playing)
            .overlay {
                switch step {
                case .selectPlayers:
                    PlayerDialog(title: "Wer spielt mit?", buttonTitle: "Weiter",
                                 players: Game.Player.allCases, color: game.color(for:),
                                 minCount: 2, maxCount: nil, selected: game.players,
                                 onSelect: { players in
                                     game = GameViewModel(players: players)
                                 }) {
                        step = .selectStartingPlayer
                    }
                case .selectStartingPlayer:
                    PlayerDialog(title: "Wer fängt an?", buttonTitle: "Los",
                                 players: Game.Player.allCases.filter(game.players.contains), color: game.color(for:),
                                 minCount: 1, maxCount: 1, selected: [game.player],
                                 onSelect: { game = GameViewModel(players: game.players, player: $0.first!) }) {
                        game.start()
                        step = .playing
                    }
                case .playing:
                    if game.isPaused || game.isOver {
                        Dialog(title: "Neues Spiel?",
                               ok: ("Neues Spiel", {
                                   game.end()
                                   game = GameViewModel()
                                   step = .selectPlayers
                               }),
                               cancel: game.isPaused
                                   ? ("Weiterspielen", { game.resume() })
                                   : nil) {}
                    }
                }
            }
            .overlay(alignment: .topTrailing) {
                if step == .playing && !(game.isPaused || game.isOver) {
                    Button { isQuitting = true } label: {
                        Image(systemName: "xmark")
                            .font(.largeTitle)
                    }
                    .foregroundStyle(.primary)
                    .padding(32)
                }
            }
            .overlay {
                if isQuitting {
                    Dialog(title: "Neues Spiel?",
                           ok: ("Neues Spiel", {
                               isQuitting = false
                               game.end()
                               game = GameViewModel()
                               step = .selectPlayers
                           }),
                           cancel: ("Weiterspielen", { isQuitting = false })) {}
                }
            }
    }
}

struct Dialog<Content: View>: View {
    let title: String
    let ok: (title: String, action: () -> Void)
    var cancel: (title: String, action: () -> Void)? = nil
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 24) {
            Text(title)
                .font(.title)

            content

            HStack(spacing: 24) {
                Button(ok.title, action: ok.action)

                if let cancel {
                    Button(cancel.title, action: cancel.action)
                }
            }
            .font(.title)
            .buttonStyle(.borderless)
            .tint(.orange)
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

    let selected: Set<Game.Player>
    let onSelect: (Set<Game.Player>) -> Void
    let onOK: () -> Void

    var body: some View {
        Dialog(title: title, ok: (buttonTitle, onOK)) {
            HStack {
                ForEach(players, id: \.self) { player in
                    PlayerButton(color: color(player), isSelected: selected.contains(player), onTap: { onSelect(selection(tapping: player)) })
                        .frame(width: 100, height: 100)
                }
            }
        }
    }

    private func selection(tapping player: Game.Player) -> Set<Game.Player> {
        if selected.contains(player) {
            selected.count > minCount ? selected.subtracting([player]) : selected
        }
        else if maxCount == 1 {
            [player]
        }
        else if selected.count < maxCount ?? players.count {
            selected.union([player])
        }
        else {
            selected
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

#Preview("New game") {
    GameView()
}

#Preview("Finishing player") {
    let labels: [Game.Player: [String]] = [
        .one: ["34", "0b", "0c", "0d"],
        .two: ["1A", "1B", "1C", "1D"],
    ]
    let pieces = labels.mapValues { Set($0.map { Game.Field($0)! }) }

    let game = try! Game(pieces: pieces, player: .one, die: .six)

    GameView(game: game)
}
