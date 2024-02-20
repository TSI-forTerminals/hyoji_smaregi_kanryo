//
//  HttpChargerServer.swift
//  smaregi_kanryo_hyoji
//
//  Created by 城川一理 on 2021/08/08.
//

import Foundation
import NIOTransportServices
import NIO

import SwiftUI

class Server {
    // MARK: - Initializers
    
    init(host: String, port: String) {
        self.host = host
        let iport = Int(port) ?? 0
        self.port = iport
    }
    //<Add 20210916 V1.7?>
    init() {
        self.host = ""
        self.port = 0
    }
    //</Add 20210916 V1.7?>
    
    // MARK: - Public functions
    func start(contentview: ContentView) {
        //stopによりgroupがnull化されていたら、再初期化を追加する
        
        do {
            let bootstrap = NIOTSListenerBootstrap(group: group)
                .childChannelInitializer { channel in
                    channel.pipeline.configureHTTPServerPipeline()
                        .flatMap {
                            channel.pipeline.addHandler(DummyHandler(contentview: contentview))
                        }
                }
            let channel = try bootstrap
                .bind(host: host, port: port)
                .wait()
            try channel.closeFuture.wait()
        } catch {
            print("An error happed \(error.localizedDescription)")
            //エラー内容確認のため無効化 exit(0)
        }
    }
    //<Add 20210916 V1.7?>
    func start(hostp: String, portp: String, contentview: ContentView) {
        self.host = hostp
        let iport = Int(portp) ?? 0
        self.port = iport
        
        do {
            let bootstrap = NIOTSListenerBootstrap(group: group)
                .childChannelInitializer { channel in
                    channel.pipeline.configureHTTPServerPipeline()
                        .flatMap {
                            channel.pipeline.addHandler(DummyHandler(contentview: contentview))
                        }
                }
            let channel = try bootstrap
                .bind(host: host, port: port)
                .wait()
            try channel.closeFuture.wait()
        } catch {
            print("An error happed \(error.localizedDescription)")
            //エラー内容確認のため無効化 exit(0)
        }
    }
    //</Add 20210916 V1.7?>
    
    func stop() {
        print("push stop")
        
        do {
            try group.syncShutdownGracefully()
        } catch {
            print("An error happed \(error.localizedDescription)")
            exit(0)
        }
    }
    // MARK: - Private properties
    private let group = NIOTSEventLoopGroup()
    private var host: String
    private var port: Int
}
