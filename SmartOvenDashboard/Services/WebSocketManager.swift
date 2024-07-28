//
//  WebSocketManager.swift
//  SmartOvenDashboard
//
//

import Foundation
import Combine
import OSLog

@MainActor class OvenDataModel: ObservableObject {
    @Published var data: SmartOvenDashboard.Payload? = nil
    
    init() {
    }
    
    init(data: SmartOvenDashboard.Payload? = nil) {
        self.data = data
    }
    
    // Function to update data
    func updateData(command: SmartOvenDashboard.Payload) {
        // This could be a network request or some other task
        self.data = command
    }
}

class WebSocketManager {
    static let shared = WebSocketManager()
    private init() {}
    

    private var webSocketTask: URLSessionWebSocketTask?

    private let stateSubject = PassthroughSubject<SmartOvenDashboard.Payload, Never>()
    var statePublisher: AnyPublisher<Payload, Never> {
        stateSubject.eraseToAnyPublisher()
    }
    
    private let devicesSubject = CurrentValueSubject<[SmartOvenDashboard.Device], Never>([])
    var devicesPublisher: AnyPublisher<[SmartOvenDashboard.Device], Never> {
        devicesSubject.eraseToAnyPublisher()
    }
    
//    private var pendingRequests: [UUID: () -> Void] = [:]
//    private let commandQueue = DispatchQueue(label: "commandQueue")
    
    var messageLog = LimitedList<String>()
    
    var connected: Bool {
        webSocketTask?.state == .running
    }
    
    func connect(token: String) {
        if webSocketTask?.state == .running {
            Logger.appLogging.debug("Websocket already Connected")
            return
        }
        
        let session = URLSession(configuration: .default)
        
        var components = URLComponents(string: "wss://devices.anovaculinary.io/")
        
        // Add query items
        components?.queryItems = [
            URLQueryItem(name: "token", value: token),
            URLQueryItem(name: "supportedAccessories", value: "APO"),
            URLQueryItem(name: "platform", value: "ios")
        ]
        
        guard let url = components?.url else {
            fatalError("Invalid URL")
        }
                
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        
        Logger.appLogging.debug("Websocket Connected")
        messageLog.append("Websocket Connected")
        
        listenForMessages()
    }
    
    private func listenForMessages() {
        Task {
            do {
                while let webSocketTask = webSocketTask {
                    let message = try await webSocketTask.receive()
                    await processReceivedMessage(message)
                }
            } catch {
                Logger.appLogging.debug("Websocket Error")
                disconnect()
            }
        }
    }
    
    private func processReceivedMessage(_ message: URLSessionWebSocketTask.Message) async {
        // Process the message
        switch message {
        case .string(let text):
            print("Received string: \(text)")
            messageLog.append(text)
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                let commandType = try decoder.decode(ApplianceCommandType.self, from: text.data(using: .utf8)!)
                print("Received : \(String(describing: commandType))")
                
                if commandType.command == "EVENT_APO_WIFI_LIST" {
                    let command = try decoder.decode(APOWifiListCommand.self, from: text.data(using: .utf8)!)
                    print("Received : \(String(describing: command))")
                    
                    devicesSubject.send(command.payload)
                }
                
                if commandType.command == "EVENT_APO_STATE" {
                    let command = try decoder.decode(ApplianceCommand.self, from: text.data(using: .utf8)!)
                    print("Received : \(String(describing: command))")
                    
                    stateSubject.send(command.payload)
                }
            }
            catch {
                messageLog.append("Error: \(error)")
                print("Error: \(error)")
            }
            
        case .data(let data):
            print("Received data: \(data)")
        }
    }
    
    func sendCommand(_ command: any APOCommand) {
        let encoder = JSONEncoder()
        let jsonData = try! encoder.encode(command)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        messageLog.append(jsonString)
        self.sendMessage(jsonString)
    }
    
    func sendMessage(_ message: String) {
        let message = URLSessionWebSocketTask.Message.string(message)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("Error sending message: \(error)")
            }
        }
    }
    
    func disconnect() {
        Logger.appLogging.debug("Websocket Disconnected")
        
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
    }
    
    deinit {
        disconnect()
    }
}
