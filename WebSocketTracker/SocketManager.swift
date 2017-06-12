//
//  SocketManager.swift
//  WebSocketTracker
//
//  Created by Douglas Barbosa on 27/05/17.
//  Copyright © 2017 Douglas Barbosa. All rights reserved.
//

import UIKit
import SocketIO

class SocketManager: NSObject {
    
    // MARK: - Properties
    
    //SocketManager singleton
    static let sharedInstance = SocketManager()
    
    //SocketIO client, it is our socket representation
    var socket: SocketIOClient = SocketIOClient(socketURL: URL(string: "http://192.168.25.2:3000")!)        
    
    //Socket connection status (Connected, Disconnected, etc)
    var connectionStatus: SocketIOClientStatus {
        return socket.status
    }
    
    // MARK: - Constructor
    
    override init() {
        super.init()
    }
    
    // MARK: - Socket connection
    
    func establishConnection() {
        socket.connect()
    }
    
    
    func closeConnection() {
        socket.disconnect()
    }
    
    //We listen to connection changes and respond accordingly
    func listenToConnectionChanges(onConnectHandler: @escaping ()->Void, onDisconnectHandler: @escaping ()->Void) {
        socket.on("connect") {  ( dataArray, ack) -> Void in            
            onConnectHandler()
        }
        
        socket.on("disconnect") {  ( dataArray, ack) -> Void in
            onDisconnectHandler()
        }
    }
    
    // MARK: - Location sharing messages
    
    //Let server know thar a user started sharing location
    func userStartedLocationSharing(withNickname nickname: String) {
        socket.emit("connectTrackedUser", nickname)
    }
    
    //Let server know thar a user stopped sharing location
    func userStoppedLocationSharing() {
        socket.emit("disconnectTrackedUser")
    }
    
    //Send to server the coordinates
    func sendCoordinates(withLatitude latitude: String, andLongitude longitude: String) {
        socket.emit("trackedUserCoordinates", latitude, longitude)
    }
    
    // MARK: - Location tracking messages
    
    //Let server know that a user started tracking a sharing location user
    func userStartedTracking(trackedUserSocketId: String, coordinatesUpdateHandler: @escaping (_ trackedUserCoordinatesUpdate: [String: AnyObject]?) -> Void, trackedUserStoppedTrackingHandler: @escaping (_ nicknameData: String?) -> Void) {
        socket.emit("connectTrackedUserTracker", trackedUserSocketId)
        
        //Listen to tracked user coordinates update
        socket.on("trackedUserCoordinatesUpdate") { ( dataArray, ack) -> Void in
            coordinatesUpdateHandler(dataArray[0] as? [String: AnyObject])
        }
        
        //Listen to whenever tracked user stops sharing location
        socket.on("trackedUserHasStoppedUpdate") { ( dataArray, ack) -> Void in
            trackedUserStoppedTrackingHandler(dataArray[0] as? String)
        }
    }
    
    //Let server know that a user stopped tracking a sharing location user
    func userStoppedTracking(trackedUserSocketId: String) {
        socket.emit("disconnectTrackedUserTracker", trackedUserSocketId)
    }
    
    // MARK: - Tracked users list monitoring
    
    //Send to server a message requesting the updated tracked users list
    func checkForUpdatedTrackedUsersList() {
        socket.emit("requestUpdatedTrackedUsersList")
    }
    
    //Listen to updated in the tracked users list
    func listenToTrackedUsersListUpdate(completionHandler: @escaping (_ trackedUsersListUpdate: [[String: AnyObject]]?) -> Void) {
        socket.on("trackedUsersListUpdate") { ( dataArray, ack) -> Void in
            completionHandler(dataArray[0] as? [[String: AnyObject]])
        }
    }

}
