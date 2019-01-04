import Dispatch
import Foundation
import Socket

protocol RemoteLintServerDelegate: AnyObject {
    func server(_ server: RemoteLintServer, didReceivePayload payload: RemoteRulePayload) -> [StyleViolation]
    func serverStartedListening(_ server: RemoteLintServer)
}

final class RemoteLintServer {
    private let socketPath: String
    private var listenSocket: Socket?
    private var continueRunning = true
    private var connectedSockets = [Int32: Socket]()
    private let socketLockQueue = DispatchQueue(label: "io.realm.swiftlint.remoteLintServer")

    weak var delegate: RemoteLintServerDelegate?

    init(socketPath: String) {
        self.socketPath = socketPath
    }

    deinit {
        for socket in connectedSockets.values {
            socket.close()
        }
        listenSocket?.close()
    }

    func run() {
        let queue = DispatchQueue.global(qos: .userInteractive)
        queue.async { [unowned self] in
            do {
                let socket = try Socket.create(family: .unix, type: .stream, proto: .unix)
                socket.readBufferSize = 65_507
                self.listenSocket = socket

                try socket.listen(on: self.socketPath)

                self.delegate?.serverStartedListening(self)

                repeat {
                    let newSocket = try socket.acceptClientConnection()
                    self.addNewConnection(socket: newSocket)
                } while self.continueRunning
            } catch {
                queuedPrintError(error)
            }
        }
    }

    private func addNewConnection(socket: Socket) {
        socketLockQueue.sync { [unowned self, socket] in
            self.connectedSockets[socket.socketfd] = socket
        }

        let queue = DispatchQueue.global(qos: .default)
        queue.async { [unowned self, socket] in
            var shouldKeepRunning = true
            var readData = Data()

            do {
                repeat {
                    let bytesRead = try socket.read(into: &readData)

                    if bytesRead > 0 {
                        guard let json = (try? JSONSerialization.jsonObject(with: readData)) as? [String: Any],
                            let payload = RemoteRulePayload(json: json) else {
                                readData.count = 0
                                break
                        }

                        let violations = self.delegate?.server(self, didReceivePayload: payload) ?? []
                        let data = try JSONSerialization.data(withJSONObject: violations.map { $0.toPluginJSON() })
                        try socket.write(from: data)
                    }

                    if bytesRead == 0 {
                        shouldKeepRunning = false
                        break
                    }

                    readData.count = 0
                } while shouldKeepRunning

                socket.close()

                self.socketLockQueue.sync { [unowned self, socket] in
                    self.connectedSockets[socket.socketfd] = nil
                }
            } catch {
                queuedPrintError(error)
            }
        }
    }

    func shutdown() {
        continueRunning = false

        for socket in connectedSockets.values {
            socket.close()
        }

        listenSocket?.close()
    }
}

private extension StyleViolation {
    func toPluginJSON() -> [String: Any] {
        return [
            "severity": severity.rawValue,
            "location": [
                "line": location.line ?? 1,
                "character": location.character ?? 1
            ],
            "reason": reason
        ]
    }
}
