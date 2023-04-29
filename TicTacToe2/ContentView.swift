//
//  ContentView.swift
//  TicTacToe2
//
//  Created by Wu, Wenpan on 2023-04-24.
//

import SwiftUI
//import SocketIO
import Starscream


enum SquareStatus {
    case empty
    case home
    case visitor
}

class Square : ObservableObject {
    @Published var squareStatus : SquareStatus
    
    init(status : SquareStatus) {
        self.squareStatus = status
    }
}


struct SquareView : View {
    @ObservedObject var dataSource : Square
    var action: () -> Void
    var body: some View {
        Button(action: {
            self.action()
        }, label: {
            Text(self.dataSource.squareStatus == .home ? "X" : self.dataSource.squareStatus == .visitor ? "O" : " ")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.black).frame(width: 70, height: 70, alignment: .center)
                .background(Color.gray.opacity(0.3).cornerRadius(10)).padding(4)
        })
    }
}
struct ContentView: View {
    @State var gameOver : Bool = false
    @StateObject var socketDelegate = WebSocket2()
    
    func buttonAction(_ index : Int) {
        let makeTurn = MakeTurn(x: index%3, y: Int(index/3))
        do {
            let jsonData = try JSONEncoder().encode(makeTurn)
            let jsonString = String(data: jsonData, encoding: .utf8)!
            socketDelegate.socket.write(string: "make_turn#\(jsonString)")
        } catch let error {
            print("Error in sending MakeTurn as JSON\n\(error)")
        }
    }
    var body: some View {
        VStack {
            Text("Tic Tac Toe")
                .bold()
                .foregroundColor(Color.black.opacity(0.7))
                .padding(.bottom)
                .font(.title2)
            Text("Player \(socketDelegate.gameState.playerAtTurn)'s turn")
                .bold()
                .foregroundColor(Color.black.opacity(0.7))
                .padding(.bottom)
                .font(.title2)
            ForEach(0 ..< Int(9 / 3), content: {
                row in
                HStack {
                    ForEach(0 ..< 3, content: {
                        column in
                        let index = row * 3 + column
                        let char = socketDelegate.gameState.field[row][column]
                        let square = Square(status: char=="X" ? .home : (char=="O" ? .visitor : .empty))
                        SquareView(dataSource: square,
                                   action: {self.buttonAction(index)})
                        
                    })
                }
            })
        }.alert(isPresented: self.$socketDelegate.gameOver, content: {
            Alert(title: Text("Game Over"),
                  message: Text(self.socketDelegate.gameState.winningPlayer != nil ?
                               "\(self.socketDelegate.gameState.winningPlayer ?? " ") Win!" : "Nobody Wins"),
            dismissButton:
                    Alert.Button.destructive(Text("Ok"), action: {
                //self.ticTacToeModel.resetGame()
            }))
        }).onAppear {
            var request = URLRequest(url: URL(string: "ws://192.168.0.19:8080/play")!)
            request.timeoutInterval = 5
            socketDelegate.connect(request: request)
        }
    }
}
class WebSocket2: NSObject, WebSocketDelegate, ObservableObject {
    let decoder = JSONDecoder()
    func didReceive(event: Starscream.WebSocketEvent, client: Starscream.WebSocket) {
        print("received: \(event)")
        switch event {
        case .connected(let headers):
            print("websocket is connected: \(headers)")
        case .disconnected(let reason, let code):
            print("websocket is disconnected: \(reason) with code: \(code)")
        case .text(let string):
            print("Recived text: \(string)")
            do {
                gameState = try decoder.decode(GameState.self, from: string.data(using: .utf8)!)
                gameOver = gameState.isBoardFull || gameState.winningPlayer != nil
                print(gameState.playerAtTurn)
            } catch let error {
                print("Error in receiving GameState as JSON\n\(error)")
            }
        default:
            break
        }
    }
    
    var socket: WebSocket!

    @Published var event: WebSocketEvent?
    @Published var gameState: GameState = GameState(playerAtTurn: "X", field: [[String?]](), winningPlayer: nil, isBoardFull: false, connectedPlayers: [String]())
    var isConnected: Bool = false
    var gameOver: Bool = false
    let server = WebSocketServer()
    var token: String = ""
    func connect(request: URLRequest) {
        socket = WebSocket(request: request)
        socket.delegate = self
        socket.connect()
    }
    override init() {
        super.init()
        for _ in 0...2 {
            var row0: [String?] = [String?]()
            row0.append(nil)
            row0.append(nil)
            row0.append(nil)
            gameState.field.append(row0)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
