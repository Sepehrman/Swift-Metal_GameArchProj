//
//  MultiplayerConnect.swift
//  Gouken
//
//  Created by Sepehr Mansouri on 2024-03-27.
//

import Foundation
import MultipeerConnectivity
import os
import Combine


enum Move: String, CaseIterable, Codable {
    case left, right, jump, crouch, lowDash, midDash, block
}

struct PlayerData: Codable {
    let data: SeralizableCharacter
    let timestamp: TimeInterval
}

struct StateData: Codable {
    let data: SerializableGameState
    let timestamp: TimeInterval
}


class MultipeerConnection: NSObject, ObservableObject {
    private let serviceType = "GoukenMP1"
    private let session: MCSession
    var receivedDataHandler: ((PlayerData) -> Void)?
    var receivedStateDataHandler: ((StateData) -> Void)?
    
    // TODO: Get the GameCenter Username from the apple device
    public let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    private let serviceAdvertiser: MCNearbyServiceAdvertiser
    private let serviceBrowser: MCNearbyServiceBrowser
    private let log = Logger()
    private var numberOfMovesSent = 0;
    private var cumulativeTime: TimeInterval = 0.0

    @Published var currentMove: String? = nil
    @Published var latency: TimeInterval = 0.0
    @Published var maxLatency: TimeInterval = 0.0
    @Published var avgLatency: TimeInterval = 0.0
    @Published var connectedPeers: [MCPeerID] = [] {
        didSet {
            // Notify observers that the connection status changed
            objectWillChange.send()
        }
    }
    // Add objectWillChange publisher
    let objectWillChange = PassthroughSubject<Void, Never>()



    override init() {
        precondition(Thread.isMainThread)
        self.session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.none)
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)

        super.init()

        session.delegate = self
        serviceAdvertiser.delegate = self
        serviceBrowser.delegate = self

        serviceAdvertiser.startAdvertisingPeer()
        serviceBrowser.startBrowsingForPeers()
    }

    deinit {
        self.serviceAdvertiser.stopAdvertisingPeer()
        self.serviceBrowser.stopBrowsingForPeers()
    }

    func send(data: SerializableGameState) {
        //precondition(Thread.isMainThread)
        if !session.connectedPeers.isEmpty {
            let timestamp = Date().timeIntervalSince1970
            let sendData = StateData(data: data, timestamp: timestamp)
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(sendData)
                try session.send(data, toPeers: session.connectedPeers, with: .unreliable)
            } catch {
                log.error("Error for sending move: \(error)")
            }
        }
    }
    
    func sendState(data: SerializableGameState) {
        //precondition(Thread.isMainThread)
        if !session.connectedPeers.isEmpty {
            let timestamp = Date().timeIntervalSince1970
            let sendData = StateData(data: data, timestamp: timestamp)
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(sendData)
                try session.send(data, toPeers: session.connectedPeers, with: .reliable)
            } catch {
                log.error("Error for sending move: \(error)")
            }
        }
    }
    
    
    func disablePlayerSearch() {
        self.serviceAdvertiser.stopAdvertisingPeer()
        self.serviceBrowser.stopBrowsingForPeers()
    }
}

extension MultipeerConnection: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        precondition(Thread.isMainThread)
        log.error("ServiceAdvertiser didNotStartAdvertisingPeer: \(String(describing: error))")
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        precondition(Thread.isMainThread)
        log.info("didReceiveInvitationFromPeer \(peerID)")
        invitationHandler(true, session)
    }
}

extension MultipeerConnection: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        log.error("ServiceBrowser didNotStartBrowsingForPeers: \(String(describing: error))")
    }

    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        log.info("ServiceBrowser found peer: \(peerID)")
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 1000)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        log.info("ServiceBrowser lost peer: \(peerID)")
    }
}
//
extension MultipeerConnection: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        log.info("peer \(peerID) didChangeState: \(state.debugDescription)")
        DispatchQueue.main.async {
            self.connectedPeers = session.connectedPeers
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do {
            let decoder = JSONDecoder()
            
//            // Attempt to decode the data as SeralizableCharacter
//            if let receivedCharacter = try? decoder.decode(PlayerData.self, from: data) {
//                if receivedCharacter.data.data == 0 {
//                    // Handle SeralizableCharacter with data = 0
//                    handleReceivedPlayerData(receivedCharacter)
//                }
//            }
            
            // Attempt to decode the data as SerializableGameState
            if let receivedGameState = try? decoder.decode(StateData.self, from: data) {
                
                handleReceivedStateData(receivedGameState)
                return
                
            }

            
        } catch {
            print("Error decoding data: \(error)")
        }
    }


    // Handler method for received PlayerData
    func handleReceivedPlayerData(_ receivedData: PlayerData) {
        DispatchQueue.main.async {
            let currentTimestamp = Date().timeIntervalSince1970
            let roundTripLatency = (currentTimestamp - receivedData.timestamp)
            self.numberOfMovesSent += 1
            self.cumulativeTime += roundTripLatency
            self.currentMove = receivedData.data.characterState.rawValue
            self.latency = roundTripLatency
            self.maxLatency = max(roundTripLatency, self.maxLatency)
            self.avgLatency = Double(self.cumulativeTime) / Double(self.numberOfMovesSent)
        }
        receivedDataHandler?(receivedData)
    }

    // Handler method for received StateData
    func handleReceivedStateData(_ receivedData: StateData) {
        DispatchQueue.main.async {
            let currentTimestamp = Date().timeIntervalSince1970
            let roundTripLatency = (currentTimestamp - receivedData.timestamp)
            self.numberOfMovesSent += 1
            self.cumulativeTime += roundTripLatency
            self.currentMove = receivedData.data.characterState.rawValue
            self.latency = roundTripLatency
            self.maxLatency = max(roundTripLatency, self.maxLatency)
            self.avgLatency = Double(self.cumulativeTime) / Double(self.numberOfMovesSent)
        }
        receivedStateDataHandler?(receivedData)
    }



    public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        log.error("Receiving streams is not supported")
    }

    public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        log.error("Receiving resources is not supported")
    }

    public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        log.error("Receiving resources is not supported")
    }
}

extension MCSessionState: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .notConnected:
            return "notConnected"
        case .connecting:
            return "connecting"
        case .connected:
            return "connected"
        @unknown default:
            return "\(rawValue)"
        }
    }
}
