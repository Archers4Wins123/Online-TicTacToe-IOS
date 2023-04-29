import SocketIO
import Foundation

class SocketHelper {

    static let shared = SocketHelper()
    var socket: SocketIOClient!

    let manager = SocketManager(socketURL: URL(string: "wss://socketsbay.com/wss/v2/1/demo/")!, config: [.log(true), .compress])

    private init() {
        socket = manager.defaultSocket
    }

    func connectSocket(completion: @escaping(Bool) -> () ) {
        disconnectSocket()
        socket.on(clientEvent: .connect) {[weak self] (data, ack) in
            print("socket connected")
            self?.socket.removeAllHandlers()
            completion(true)
        }
        socket.connect()
    }

    func disconnectSocket() {
        socket.removeAllHandlers()
        socket.disconnect()
        print("socket Disconnected")
    }

    func checkConnection() -> Bool {
        if socket.manager?.status == .connected {
            return true
        }
        return false

    }

    enum Events {

        case search
        var listnerName: String {
                    switch self {
                    case .search:
                        return "filtered_tags"
                    }
                }

        func emit(params: [String : Any]) {
            SocketHelper.shared.socket.emit("emt_search_tags", params)
        }

        func listen(completion: @escaping (Any) -> Void) {
            SocketHelper.shared.socket.on("filtered_tags") { (response, emitter) in
                completion(response)
            }
        }

        func off() {
            SocketHelper.shared.socket.off(listnerName)
        }
    }
}
