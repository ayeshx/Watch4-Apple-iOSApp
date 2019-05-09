//
//  SessionHandler.swift
//  watchtest
//
//  Created by user on 5/6/19.
//  Copyright © 2019 user. All rights reserved.
//

import Foundation
import WatchConnectivity
import Moscapsule

class SessionHandler : NSObject, WCSessionDelegate {
    let mqttConfig = MQTTConfig(clientId: "cid", host: "192.168.0.111", port: 1883, keepAlive: 60)
    
    var mqttClient: MQTTClient? = nil
    var watchData = ["x":"","y":"","z":"","roundtrip_time":""]
    var start = false
    var initTime = Int64(0)
    // 1: Singleton
    static let shared = SessionHandler()
    
    // 2: Property to manage session
    private var session = WCSession.default
    
    override init() {
        super.init()
        
        // 3: Start and avtivate session if it's supported
        if isSuported() {
            session.delegate = self
            session.activate()
        }
        mqttConfig.onMessageCallback = { mqttMessage in
            NSLog("MQTT Message received: payload=\(mqttMessage.payloadString)")
            if mqttMessage.payloadString == "start"{
                self.start = true;
            } else if mqttMessage.payloadString == "kill" {
                self.start = false;
            } else if mqttMessage.payloadString == "ack" {
                self.watchData["roundtrip_time"] = String(Int64(Date().timeIntervalSince1970 * 1000) - self.initTime)
                let sendData = try! JSONEncoder().encode(self.watchData)
                let jsonString = String(data: sendData, encoding: .utf8)!
                //            print(jsonString)
                ////            var publishString = "{X:"+watchData["X"] +",Y:"+watchData["Y"] + ",Z:"+watchData["Z"]+"}"
                self.mqttClient?.publish(string:jsonString , topic: "watch4/finaldata", qos: 0, retain: false)
            }
        }
        mqttConfig.onConnectCallback = { returnCode in
            NSLog("Return Code is \(returnCode.description)")
        }
        mqttClient = MQTT.newConnection(mqttConfig, connectImmediately: true)
        // Do any additional setup after loading the view.
        mqttConfig.onPublishCallback = { messageId in
            print("published (msg id=\(messageId)))")
        }
        // publish and subscribe
        mqttClient?.subscribe("watch4/start", qos: 0)
        mqttClient?.subscribe("watch4/ack", qos: 0)
        mqttClient?.subscribe("watch4/kill", qos: 0)
        print("isPaired?: \(session.isPaired), isWatchAppInstalled?: \(session.isWatchAppInstalled)")
    }
    
    func isSuported() -> Bool {
        return WCSession.isSupported()
    }
    
    
    // MARK: - WCSessionDelegate
    
    // 4: Required protocols
    
    // a
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("activationDidCompleteWith activationState:\(activationState) error:\(String(describing: error))")
    }
    
    // b
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("sessionDidBecomeInactive: \(session)")
    }
    
    // c
    func sessionDidDeactivate(_ session: WCSession) {
        print("sessionDidDeactivate: \(session)")
        // Reactivate session
        /**
         * This is to re-activate the session on the phone when the user has switched from one
         * paired watch to second paired one. Calling it like this assumes that you have no other
         * threads/part of your code that needs to be given time before the switch occurs.
         */
        self.session.activate()
    }
    
    /// Observer to receive messages from watch and we be able to response it
    ///
    /// - Parameters:
    ///   - session: session
    ///   - message: message received
    ///   - replyHandler: response handler
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        if message["x"] is String && self.start == true {
            replyHandler(["reply" : "Got your coords"])
            watchData["x"] = message["x"] as? String
            watchData["y"] = message["y"] as? String
            watchData["z"] = message["z"] as? String
            initTime = Int64(Date().timeIntervalSince1970 * 1000)
//            watchData["Y"] = message["Y"] as! String
//            watchData["Z"] = message["Z"] as! String
            print(watchData["x"] ?? "Empty")
//            var string1 = "Hello"+" there"
            let sendData = try! JSONEncoder().encode(watchData)
            let jsonString = String(data: sendData, encoding: .utf8)!
//            print(jsonString)
////            var publishString = "{X:"+watchData["X"] +",Y:"+watchData["Y"] + ",Z:"+watchData["Z"]+"}"
            mqttClient?.publish(string:jsonString , topic: "watch4/watchdata", qos: 0, retain: false)
        } else {
            replyHandler(["reply":"Got your string coords"])
        }
    }
    
}
