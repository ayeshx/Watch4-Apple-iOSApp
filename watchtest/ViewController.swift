//
//  ViewController.swift
//  watchtest
//
//  Created by user on 4/28/19.
//  Copyright © 2019 user. All rights reserved.
//

import UIKit
import Moscapsule
import WatchConnectivity

class ViewController: UIViewController {
//    // set MQTT Client Configuration
//    let mqttConfig = MQTTConfig(clientId: "cid", host: "192.168.0.111", port: 1883, keepAlive: 60)
//
//
//    // create new MQTT Connection
//    var mqttClient: MQTTClient? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        

        
//        mqttConfig.onMessageCallback = { mqttMessage in
//            NSLog("MQTT Message received: payload=\(mqttMessage.payloadString)")
//        }
//        mqttConfig.onConnectCallback = { returnCode in
//            NSLog("Return Code is \(returnCode.description)")
//        }
//        mqttClient = MQTT.newConnection(mqttConfig, connectImmediately: true)
//        // Do any additional setup after loading the view.
//        mqttConfig.onPublishCallback = { messageId in
//            print("published (msg id=\(messageId)))")
//        }
//        // publish and subscribe
//        mqttClient?.publish(string: "message", topic: "publish/topic", qos: 2, retain: false)
//        mqttClient?.subscribe("publish/topic", qos: 2)
    }


}

