//
//  ViewController.swift
//  app
//
//  Created by Key.Yao on 2020/2/23.
//  Copyright © 2020 Key.Yao. All rights reserved.
//

import UIKit
import SnapKit
import MqttLibrary

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        layout()
        
        MqttClient.share().eventDelegate = self
    }
    
    deinit {
        MqttClient.share().eventDelegate = nil
    }

}

extension ViewController {
    
    private func layout() {
        title = "mqtt_client_ios"
        
        let startButton = UIButton(type: .custom)
        startButton.setTitle("Start Service", for: .normal)
        startButton.backgroundColor = .blue
        startButton.layer.cornerRadius = 5
        startButton.clipsToBounds = true
        startButton.addTarget(self, action: #selector(onClickStartButton), for: .touchUpInside)
        self.view.addSubview(startButton)
        startButton.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalToSuperview().offset(120)
            make.height.equalTo(38)
        }
        
        let subscribeButton = UIButton(type: .custom)
        subscribeButton.setTitle("Subscribe", for: .normal)
        subscribeButton.backgroundColor = .blue
        subscribeButton.layer.cornerRadius = 5
        subscribeButton.clipsToBounds = true
        subscribeButton.addTarget(self, action: #selector(onClickSubscribeButton), for: .touchUpInside)
        self.view.addSubview(subscribeButton)
        subscribeButton.snp.makeConstraints { (make) in
            make.left.right.height.equalTo(startButton)
            make.top.equalTo(startButton.snp.bottom).offset(20)
        }
        
        let unsubscribeButton = UIButton(type: .custom)
        unsubscribeButton.setTitle("Unsubscribe", for: .normal)
        unsubscribeButton.backgroundColor = .blue
        unsubscribeButton.layer.cornerRadius = 5
        unsubscribeButton.clipsToBounds = true
        unsubscribeButton.addTarget(self, action: #selector(onClickUnsubscribeButton), for: .touchUpInside)
        self.view.addSubview(unsubscribeButton)
        unsubscribeButton.snp.makeConstraints { (make) in
            make.left.right.height.equalTo(startButton)
            make.top.equalTo(subscribeButton.snp.bottom).offset(20)
        }
        
        let publishButton = UIButton(type: .custom)
        publishButton.setTitle("Publish", for: .normal)
        publishButton.backgroundColor = .blue
        publishButton.layer.cornerRadius = 5
        publishButton.clipsToBounds = true
        publishButton.addTarget(self, action: #selector(onClickPublishButton), for: .touchUpInside)
        self.view.addSubview(publishButton)
        publishButton.snp.makeConstraints { (make) in
            make.left.right.height.equalTo(startButton)
            make.top.equalTo(unsubscribeButton.snp.bottom).offset(20)
        }
        
    }
    
    @objc private func onClickStartButton() {
        //let caFilePath = Bundle(for: self.classForCoder).path(forResource: "ca", ofType: "crt") ?? ""
        
        MqttClient.share().start(withHost: "192.168.1.101", port: 1883, uuid: "mqtt_ios_client", clearSession: false)
        //MqttClient.share().start(withHost: "192.168.1.101", port: 8883, uuid: "mqtt_ios_client", clearSession: false, caFilePath: caFilePath, username: "username", password: "password")
    }
    
    @objc private func onClickSubscribeButton() {
        let topic = "/android/test/topicA"
        MqttClient.share().subscribeTopic(topic)
    }
    
    @objc private func onClickUnsubscribeButton() {
        let topic = "/android/test/topicA"
        MqttClient.share().unsubscribeTopic(topic)
    }
    
    @objc private func onClickPublishButton() {
        let topic = "/android/test/topicA"
        let message = "test message from ios"
        MqttClient.share().publishMessage(message, forTopic: topic)
    }

    
}

extension ViewController: MqttEventDelegate {
    
    func onMessage(_ message: String, forTopic topic: String) {
        print("==== onMessage: \(message) | topic: \(topic)")
    }
    
    func onConnnect() {
        print("==== onConnect")
    }
    
    func onConnnect(withFlag flags: Int) {
        print("==== onConnect flag: \(flags)")
    }
    
    func onDisconnect() {
        print("==== onDisconnect")
    }
    
    func onPublish() {
        print("==== onPublish")
    }
    
    func onSubscribe() {
        print("==== onSubscribe")
    }
    
    func onUnsubscribe() {
        print("==== onUnsubscribe")
    }
    
    func onLog(_ log: String, forLevel level: Int) {
        print("==== onLog: \(log) | levet: \(level)")
    }
    
}

