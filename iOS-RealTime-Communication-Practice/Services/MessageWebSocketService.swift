//
//  MessageWebSocketService.swift
//  iOS-RealTime-Communication-Practice
//
//  Created by wyn on 2024/9/23.
//

import Combine
import Foundation

final class DefaultMessageWebSocketService {
    private let dataTransfer: DataTransfer
    private let webSocketTask: URLSessionWebSocketTask
    private var cancellables = Set<AnyCancellable>()
    
    init(dataTransfer: DataTransfer = DefaultDataTransfer()) {
        self.dataTransfer = dataTransfer
        guard let url = URL(string: APIEndpoints.websocket) else { fatalError("Invalid URL") }
        let urlSession = URLSession(configuration: .default)
        self.webSocketTask = urlSession.webSocketTask(with: url)
    }
}

extension DefaultMessageWebSocketService: MessageService {
    func sendMsg(_ message: String) async throws {
        let message = URLSessionWebSocketTask.Message.string(message)
        try await webSocketTask.send(message)
    }

    func readMsgs() async throws -> [String] {
        return []
    }

    func setupConnection() -> AnyPublisher<String, Error> {
        webSocketTask.resume()
        
        let subject = PassthroughSubject<String, Error>()
        
        func receiveMessage() {
            webSocketTask.receive { result in
                switch result {
                case .success(let message):
                    switch message {
                    case .string(let text):
                        subject.send(text)
                    case .data(let data):
                        if let text = String(data: data, encoding: .utf8) {
                            subject.send(text)
                        }
                    default:
                        break
                    }
                    receiveMessage()
                case .failure(let error):
                    subject.send(completion: .failure(error))
                }
            }
        }
        receiveMessage()
        
        return subject.eraseToAnyPublisher()
    }
}