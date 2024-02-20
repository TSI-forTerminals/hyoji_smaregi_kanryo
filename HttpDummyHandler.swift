//
//  HttpDummyHandler.swift
//  smaregi_kanryo_hyoji
//
//  Created by 城川一理 on 2021/08/08.
//

import Foundation
import NIOHTTP1
import NIO

import Network

import SwiftUI

final class DummyHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart
    
    //@EnvironmentObject var dispitems: DispItems
    private var cntv: ContentView
    init(contentview: ContentView) {
        self.cntv = contentview
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let part = self.unwrapInboundIn(data)
        guard case .head = part else {
            return
        }
        
        //partからuriを取りだして処理を振り分ける
        var apiuri: String = ""
        //var apiquery: String = ""
        switch part {
        case .head(let request):
            apiuri = request.uri
            //apiquery = request.uri.
        default:
            return
        }
        
        var apiname: String = "noapi"
        var billingamount = cntv.dispitems.billingamount
        var ibillingaount: Int32 = Int32(billingamount) ?? 0
        var depositamount = cntv.dispitems.depositamount
        var idepositamount: Int32 = Int32(depositamount) ?? 0
        var minusamount = cntv.dispitems.minusamount
        var iminusamount: Int32 = Int32(minusamount) ?? 0
        var chargeamount = cntv.dispitems.chargeamount
        var ichargeamount: Int32 = Int32(chargeamount) ?? 0
        var message = ["message": "Hello TSI"]
        
        let comp: NSURLComponents? = NSURLComponents(string: "http://hoge.com" + apiuri)
        let querydic: Dictionary<String, String>? = urlComponentsToDict(comp: comp!)
        
        //url名で処理を振り分ける
        //var query: URL=URL(string: apiuri)!
        //確認状態設定
        if apiuri.unicodeScalars.starts(with: "/confset".unicodeScalars){
            let confirmstatus: String = querydic?["confirmstatus"] ?? ""
            if (confirmstatus.count != 0){
                //ステータスの設定値が指定されている時だけ
                DispatchQueue.main.sync {
                    self.cntv.dispitems.confirmstatus = confirmstatus
                }
            }
            let announce: String = querydic?["announce"] ?? ""
            if (announce.count != 0){
                //アナウンスの設定値が指定されている時だけ
                DispatchQueue.main.sync {
                    self.cntv.dispitems.announce = announce
                }
            }
            apiname = "confset->" + cntv.dispitems.confirmstatus + "," + cntv.dispitems.announce
            
            //各ステータスをJsonで返却
            message = ["message": apiname]
        }
        //ステータス要求
        if apiuri.unicodeScalars.starts(with: "/enqsend".unicodeScalars){
            //ENQ送信
            apiname = enq_telegram_get(host: cntv.dispitems.changerip, port: cntv.dispitems.changerport)
            //apiname = cntv.dispitems.chargerstatus
            //apiname = "tuuka"
            
            let date = Date()
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .medium
            //apiname = "enq->" + apiname + formatter.string(from: date) //cntv.dispitems.chargerstatus
            message = ["message": apiname]
            
            DispatchQueue.main.sync {
                self.cntv.dispitems.chargerstatus = apiname
            }
            
        }
        //送信終了(通信初期化)
        if apiuri.unicodeScalars.starts(with: "/eotsend".unicodeScalars){
            apiname = eot_telegram_get(host: cntv.dispitems.changerip, port: cntv.dispitems.changerport)
            //apiname = "eot->" + cntv.dispitems.chargerstatus
            
            message = ["message": apiname]
        }
        //精査コマンド
        if apiuri.unicodeScalars.starts(with: "/seisa".unicodeScalars){
            //精査送信
            apiname = seisa_telegram_get(host: cntv.dispitems.changerip, port: cntv.dispitems.changerport, delay: 0)
            //apiname = cntv.dispitems.chargerstatus
            //<テスト用>
            //let bln = chargeable(chargeamount: 200)
            //if (bln){
            //}
            //</テスト用>
            
            message = ["message": apiname]
            
            DispatchQueue.main.sync {
                self.cntv.dispitems.chargerstatus = apiname
            }
            
        }
        //預り金計数開始
        if apiuri.unicodeScalars.starts(with: "/keisustart".unicodeScalars){
            //請求金額の設定
            billingamount = querydic?["price"] ?? "0"
            //会員コード・名前の設定
            DispatchQueue.main.sync{
                self.cntv.dispitems.customercode = querydic?["customercode"] ?? ""
                self.cntv.dispitems.customername = querydic?["customername"] ?? ""
                //確認ボタンを非表示
                self.cntv.dispitems.confirmstatus = "0"
                //アナウンス
                //<Del 20210903/>self.cntv.dispitems.announce = "投入口にお金を入れて下さい。"
                self.cntv.dispitems.announce = "※お金を投入したら精算ボタンを押して下さい。"
            }
            
            //釣銭機へ送信　読取開始
            //debug
            //<Upd 20210924 V1.8>
            //apiname = keisustart_telegram_get(host: cntv.dispitems.changerip, port: cntv.dispitems.changerport)
            if billingamount != "0" {
                apiname = keisustart_telegram_get(host: cntv.dispitems.changerip, port: cntv.dispitems.changerport)
                //<Add 20211120 コマンドのすっぽ抜け回避？ V1.19>
                var iRp:Int = 0
                while (apiname != "ACK"){
                    apiname = keisustart_telegram_get(host: cntv.dispitems.changerip, port: cntv.dispitems.changerport)
                    iRp += 1
                    if iRp > 5 {
                        break
                    }
                }
                //</Add 20211120 コマンドのすっぽ抜け回避？ V1.19>
            }
            //</Upd 20210924 V1.8>
            //apiname = "keisustart->" + cntv.dispitems.chargerstatus
            
            message = ["message": apiname]
        }
        //投入金額計数リード
        if apiuri.unicodeScalars.starts(with: "/keisuread".unicodeScalars){
            chargeamount = "0"//<Add 20220422 お釣り過剰支払回避 ver1.30>
            //<Add 20220421 計数時間超過対応 ver1.30>
            let dblReadStart = Double(Date().timeIntervalSince1970)
            //</Add 20220421 計数時間超過対応 ver1.30>

            //釣り銭機に投入された金額を取得
            apiname = keisuread_telegram_get(host: cntv.dispitems.changerip, port: cntv.dispitems.changerport, delay: 0)
            //<Add 20211112 ver1.16>
            var iEnd :Int = 1
            while (apiname == ""){
                Thread.sleep(forTimeInterval: 0.1)
                apiname = keisuread_telegram_get(host: cntv.dispitems.changerip, port:cntv.dispitems.changerport, delay: iEnd)
                iEnd += 1
                if (iEnd > 4){
                    break
                }
            }
            //</Add 20211112 ver1.16>

            //</Add 20220421 計数時間超過対応 ver1.30>
            //計数リードに５秒以上掛かったらログに残す
            let dblNow = Double(Date().timeIntervalSince1970)
            let time = Int(dblNow - dblReadStart)
            if time >= 5{
                TSILog.write("keisuread Timeout発生!!" + time.description + "sec Over",funcnm: #function,line: #line, loguse: cntv.dispitems.loguse)
            }
            //</Add 20220421 計数時間超過対応 ver1.30>

            //↓debug用
            /*
             idepositamount = Int32(depositamount) ?? 0
             if cntv.dispitems.confirmstatus == "0"
             {
             idepositamount += 100
             }
             depositamount = idepositamount.description
             
             var dic = Dictionary<String, String>()
             var jstr: String = ""
             dic["計数情報"] = "0"
             dic["計数停止"] = "0"
             dic["装置状態"] = "0"
             dic["合計金額"] = depositamount
             do {
             // DictionaryをJSONデータに変換
             let jsonData = try JSONSerialization.data(withJSONObject: dic)
             // JSONデータを文字列に変換
             jstr = String(bytes: jsonData, encoding: .utf8)!
             print(jstr)
             } catch (let e) {
             print(e)
             }
             apiname = jstr
             */
            //↑debug用
            
            //表示用に投入金額を取得
            let jsondata: Data = apiname.data(using: String.Encoding.utf8)! //Json変換するには文字列はData型にする
            if (apiname.starts(with: "{")){
                do {
                    var chresp = try JSONSerialization.jsonObject(with: jsondata) as! Dictionary<String, Any>
                    depositamount = chresp["合計金額"] as! String
                    
                    //各表示金額を計算
                    idepositamount = Int32(depositamount) ?? 0
                    iminusamount = idepositamount
                    iminusamount -= ibillingaount
                    if (iminusamount >= 0) {
                        //不足額が無くなった時
                        ichargeamount = idepositamount - ibillingaount
                        iminusamount = 0
                        if (cntv.dispitems.confirmstatus == "0") {
                            if (chargeable(chargeamount: Int(ichargeamount))){
                                DispatchQueue.main.async {
                                    self.cntv.dispitems.confirmstatus = "1" //確認ボタン表示中
                                    self.cntv.dispitems.announce = "表示されている投入金額に誤りがなければ、精算ボタンを押して下さい。" //確認ボタン表示中
                                }
                            }else{
                                DispatchQueue.main.async {
                                    self.cntv.dispitems.announce = "おつりが不足しています。" //確認ボタン表示不可
                                }
                            }
                        }
                    }
                    minusamount = iminusamount.description
                    chargeamount = ichargeamount.description
                    //釣銭金額・確認状態を追加して返却する
                    chresp["釣銭金額"] = chargeamount
                    chresp["確認状態"] = cntv.dispitems.confirmstatus
                    do {
                        // DictionaryをJSONデータに変換
                        let jsonData = try JSONSerialization.data(withJSONObject: chresp)
                        // JSONデータを文字列に変換
                        apiname = String(bytes: jsonData, encoding: .utf8)!
                    } catch (let e) {
                        print(e)
                    }
                } catch {
                    print(error)
                }
            }
            else{
                //apinameは""。釣銭金額・確認状態等のステータスは全く渡らない
            }
            print("取得内容:" + apiname)
            
            //投入金額、各ステータスをJsonで返却
            message = ["message": apiname]
        }
        //投入金額計数停止予約
        if apiuri.unicodeScalars.starts(with: "/keisustop".unicodeScalars){
            apiname = keisustop_telegram_get(host: cntv.dispitems.changerip, port: cntv.dispitems.changerport)
            //<Add 20211120 コマンドのすっぽ抜け回避？ V1.19>
            var iRp:Int = 0
            while (apiname != "ACK"){
                apiname = keisustop_telegram_get(host: cntv.dispitems.changerip, port: cntv.dispitems.changerport)
                iRp += 1
                if iRp > 5 {
                    break
                }
            }
            //</Add 20211120 コマンドのすっぽ抜け回避？ V1.19>
            //apiname = "keisustop->" + cntv.dispitems.chargerstatus
            
            //各ステータスをJsonで返却
            message = ["message": apiname]
        }
        //投入金額計数停止
        if apiuri.unicodeScalars.starts(with: "/keisuend".unicodeScalars){
            apiname = keisuend_telegram_get(host: cntv.dispitems.changerip, port: cntv.dispitems.changerport)
            //<Add 20211120 コマンドのすっぽ抜け回避？ V1.19>
            var iRp:Int = 0
            while (apiname != "ACK"){
                apiname = keisuend_telegram_get(host: cntv.dispitems.changerip, port: cntv.dispitems.changerport)
                iRp += 1
                if iRp > 5 {
                    break
                }
            }
            //</Add 20211120 コマンドのすっぽ抜け回避？ V1.19>
            //apiname = "keisuend->" + cntv.dispitems.chargerstatus
            
            //各ステータスをJsonで返却
            message = ["message": apiname]
        }
        //投入金額計数再開
        if apiuri.unicodeScalars.starts(with: "/keisurestart".unicodeScalars){
            apiname = keisurestart_telegram_get(host: cntv.dispitems.changerip, port: cntv.dispitems.changerport)
            //apiname = "keisurestart->" + cntv.dispitems.chargerstatus
            
            //各ステータスをJsonで返却
            message = ["message": apiname]
        }
        //釣銭放出
        if apiuri.unicodeScalars.starts(with: "/payout".unicodeScalars){
            let chargeamt: String = querydic?["charge"] ?? ""
            //おつりを放出する
            if (chargeamt.count==0){ //パラメータからの金額指定なし
                apiname = payout6_telegram_get(host: cntv.dispitems.changerip, port: cntv.dispitems.changerport, amount: cntv.dispitems.chargeamount)
            }
            else{
                apiname = payout6_telegram_get(host: cntv.dispitems.changerip, port: cntv.dispitems.changerport, amount: chargeamt)
            }
            //apiname = "payout->" + cntv.dispitems.chargerstatus
            
            //各ステータスをJsonで返却
            message = ["message": apiname]
        }
        
        //<Add 20210914 ver1.5>
        //投入金額放出
        if apiuri.unicodeScalars.starts(with: "/cancelpayout".unicodeScalars){
            //投入金額＝０の判定は、上位処理に任せる？
            var strPieces = keisuread_telegram_get(host: cntv.dispitems.changerip, port: cntv.dispitems.changerport, delay: 0)
            if (strPieces.starts(with: "{")){
                //放出
                apiname = payout_telegram_get(host: cntv.dispitems.changerip, port: cntv.dispitems.changerport, pieces: strPieces)
            }else{
                //エラー時
                apiname = strPieces
            }
            
            //各ステータスをJsonで返却
            message = ["message": apiname]
        }
        //</Add 20210914 ver1.5>
        
        //画面リセット
        if apiuri.unicodeScalars.starts(with: "/resetdisp".unicodeScalars){
            //表示画面をクリアする
            billingamount = "0"
            depositamount = "0"
            minusamount = "0"
            chargeamount = "0"
            DispatchQueue.main.sync {
                cntv.dispitems.announce = ""
                cntv.dispitems.confirmstatus = "0"
                cntv.dispitems.customercode = ""
                cntv.dispitems.customername = ""
                cntv.dispitems.jusinOK = "●受信OK" //<Add 20210927 V1.8? />
            }
            
            apiname = "resetdisp->Done"// + cntv.dispitems.chargerstatus
            
            //各ステータスをJsonで返却
            message = ["message": apiname]
        }
        //リセット ★urlの変更要
        if apiuri.unicodeScalars.starts(with: "/resetcharger".unicodeScalars){
            //メカニカルイニシャルを実行する
            apiname = reset_telegram_get(host: cntv.dispitems.changerip, port: cntv.dispitems.changerport)
            //apiname = "reset->" + cntv.dispitems.chargerstatus
            
            //各ステータスをJsonで返却
            message = ["message": apiname]
        }
        //<Add 20211101 精算後に読み取りバッファをクリアする>
        //計数リセット
        if apiuri.unicodeScalars.starts(with: "/keisureset".unicodeScalars){
            apiname = keisustart_telegram_get(host: cntv.dispitems.changerip, port: cntv.dispitems.changerport)
            apiname = keisustop_telegram_get(host: cntv.dispitems.changerip, port: cntv.dispitems.changerport)
            apiname = keisuend_telegram_get(host: cntv.dispitems.changerip, port: cntv.dispitems.changerport)
            //apiname = "reset->" + cntv.dispitems.chargerstatus
            
            //各ステータスをJsonで返却
            message = ["message": apiname]
        }
        //</Add 20211101>
        
        //画面への書き出し
        DispatchQueue.main.sync { //[weak self] in
            //print("main.sync")
            //cntv.dispitems.announce = apiname
            cntv.dispitems.billingamount = billingamount
            cntv.dispitems.depositamount = depositamount
            cntv.dispitems.minusamount = minusamount
            cntv.dispitems.chargeamount = chargeamount
        }
        
        // Prepare the response body
        let response = try! JSONEncoder().encode(message)
        // set the headers
        var headers = HTTPHeaders()
        headers.add(name: "Content-Type", value: "application/json")
        headers.add(name: "Content-Length", value: "\(response.count)")
        headers.add(name: "Connection", value: "close")//※この設定が無いとクライアント側がタイムアウトエラーになる
        let responseHead = HTTPResponseHead(version: .init(major: 1, minor: 1), status: .ok, headers: headers)
        context.write(self.wrapOutboundOut(.head(responseHead)), promise: nil)
        // Set the data
        var buffer = context.channel.allocator.buffer(capacity: response.count)
        buffer.writeBytes(response)
        let body = HTTPServerResponsePart.body(.byteBuffer(buffer))
        context.writeAndFlush(self.wrapOutboundOut(body), promise: nil)
    }
    
    func urlComponentsToDict(comp:NSURLComponents) -> Dictionary<String, String> {
        var dict:Dictionary<String, String> = Dictionary<String, String>()
        
        comp.queryItems?.forEach({ qitem in
            dict[qitem.name] = qitem.value
        })
        
        return dict
    }
    
    //Network.frameworkを使ったTCPソケット通信
    //送信
    func send(connection: NWConnection, sendbytes:[UInt8]) {
        //let message = "\n"
        //let data = message.data(using: .utf8)!
        let data = sendbytes
        let semaphore = DispatchSemaphore(value: 0)
        
        connection.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                NSLog("sendエラー発生 \(#function), \(error)")
            } else {
                //下に移動?
                semaphore.signal()
            }
            //semaphore.signal()
        })
        
        semaphore.wait()
    }
    //バイト配列を文字列にする(数字の範囲のみ処理対象)
    func bytetohexstr(inbyte:[UInt8])->String{
        var strHex: String = ""
        for i in 0..<inbyte.count{
            if(inbyte[i] != 0x00){
                /*
                 if (inbyte[i] >= 48 && inbyte[i] < 58){
                 strHex += String(inbyte[i]-48) + "h"
                 }else{
                 strHex += String(inbyte[i]) + "h"
                 }
                 */
                strHex += String(format: "%02x", inbyte[i]) + "h"
            }
        }
        return strHex
    }
    //計数リード時のレスポンスをjson変換する
    func KEISUResponse(strHx: String)->String
    {
        let aHex: [Substring] = strHx.split(separator: "h");
        var dic = Dictionary<String, String>()
        var amount:Int = 0
        var jstr: String = ""
        
        if (aHex.count < 41) {//<Upd 2021108 40->41>
            return ""
        }
        
        dic["計数情報"] = String(aHex[4].suffix(1))
        dic["計数停止"] = String(aHex[5].suffix(1))
        dic["装置状態"] = String(aHex[6].suffix(1))
        dic["紙幣挿入口情報"] = String(aHex[7].suffix(1))
        dic["紙幣部詳細情報"] = String(aHex[8].suffix(1))
        dic["硬貨投入口情報"] = String(aHex[9].suffix(1))
        dic["硬貨部詳細情報"] = String(aHex[10].suffix(1))
        
        var strMai: String = ""
        strMai = String(aHex[11].suffix(1))
        strMai += String(aHex[12].suffix(1))
        strMai += String(aHex[13].suffix(1))
        dic["10000円"] = strMai
        amount += 10000 * (Int(strMai) ?? 0)
        
        strMai = String(aHex[14].suffix(1))
        strMai += String(aHex[15].suffix(1))
        strMai += String(aHex[16].suffix(1))
        dic["5000円"] = strMai
        amount += 5000 * (Int(strMai) ?? 0)
        
        strMai = String(aHex[17].suffix(1))
        strMai += String(aHex[18].suffix(1))
        strMai += String(aHex[19].suffix(1))
        dic["2000円"] = strMai
        amount += 2000 * (Int(strMai) ?? 0)
        
        strMai = String(aHex[20].suffix(1))
        strMai += String(aHex[21].suffix(1))
        strMai += String(aHex[22].suffix(1))
        dic["1000円"] = strMai
        amount += 1000 * (Int(strMai) ?? 0)
        
        strMai = String(aHex[23].suffix(1))
        strMai += String(aHex[24].suffix(1))
        strMai += String(aHex[25].suffix(1))
        dic["500円"] = strMai
        amount += 500 * (Int(strMai) ?? 0)
        
        strMai = String(aHex[26].suffix(1))
        strMai += String(aHex[27].suffix(1))
        strMai += String(aHex[28].suffix(1))
        dic["100円"] = strMai
        amount += 100 * (Int(strMai) ?? 0)
        
        strMai = String(aHex[29].suffix(1))
        strMai += String(aHex[30].suffix(1))
        strMai += String(aHex[31].suffix(1))
        dic["50円"] = strMai
        amount += 50 * (Int(strMai) ?? 0)
        
        strMai = String(aHex[32].suffix(1))
        strMai += String(aHex[33].suffix(1))
        strMai += String(aHex[34].suffix(1))
        dic["10円"] = strMai
        amount += 10 * (Int(strMai) ?? 0)
        
        strMai = String(aHex[35].suffix(1))
        strMai += String(aHex[36].suffix(1))
        strMai += String(aHex[37].suffix(1))
        dic["5円"] = strMai
        amount += 5 * (Int(strMai) ?? 0)
        
        strMai = String(aHex[38].suffix(1))
        strMai += String(aHex[39].suffix(1))
        strMai += String(aHex[40].suffix(1))
        dic["1円"] = strMai
        amount += Int(strMai) ?? 0
        
        dic["合計金額"] = String(amount)
        
        do {
            // DictionaryをJSONデータに変換
            let jsonData = try JSONSerialization.data(withJSONObject: dic)
            // JSONデータを文字列に変換
            jstr = String(bytes: jsonData, encoding: .utf8)!
        } catch (let e) {
            print(e)
        }
        return jstr
    }
    
    //ENQ,KeisuStart,keisuread受信
    //https://www.radical-dreamer.com/programming/raspberry-pi-bme280-client/#toc10
    func recv_enq(connection: NWConnection) -> String {
        var strRtn: String = ""
        
        let semaphore = DispatchSemaphore(value: 0)
        connection.receive(minimumIncompleteLength: 0, maximumLength: 4096, completion:{(data, context, flag, error) in
            if let error = error {
                NSLog("\(#function), \(error)")
            } else {
                if let data = data {
                    let bytes:[UInt8] = [UInt8](data)
                    var retname: String = ""
                    if(bytes.count > 0){
                        switch bytes[0] {
                        case 0x06: //正常終了
                            retname = "ACK"
                        case 0x18: //異常終了
                            retname = "CAN"
                        case 0x17: //ニアエンプティ
                            retname = "CAN"
                        case 0x15: //通信異常
                            retname = "NAK"
                        case 0x13: //セットはずれ
                            retname = "DC3"
                        case 0x1A: //動作中
                            retname = "SUB"
                        case 0x14: //放出可動作中
                            retname = "DC4"
                        case 0x01: //計数中
                            retname = "SOH"
                        case 0x19: //計数停止中
                            retname = "EM"
                        case 0x07: //動作不可
                            retname = "BEL"
                        case 0x12: //抜き取り待ち
                            retname = "DC2"
                        case 0x10: //レスポンスの先頭
                            retname = "DLE"
                        default:
                            retname = ""
                        }
                        //2バイト以上のリターンからの編集
                        if(bytes.count > 1){
                            retname = self.bytetohexstr(inbyte: bytes)
                            print("16進電文:" + retname)
                            retname = self.KEISUResponse(strHx: retname)
                        }
                    }
                    print(retname)//<Add 20211108>
                    print("Flag:" + flag.description)
                    //print("取得内容:" + retname)
                    strRtn = retname
                    
                    DispatchQueue.main.async {
                        self.cntv.dispitems.chargerstatus = retname
                    }
                    //下に移動?
                    semaphore.signal()
                }
                else {
                    NSLog("receiveMessage data nil")
                }
            }
            //semaphore.signal()
        })
        
        semaphore.wait()
        
        return strRtn
    }
    
    //<Add 20211115 V1.16>
    //keisuread受信
    //https://www.radical-dreamer.com/programming/raspberry-pi-bme280-client/#toc10
    func recv_keisuread(connection: NWConnection) -> String {
        var strRtn: String = ""
        
        let semaphore = DispatchSemaphore(value: 0)
        connection.receive(minimumIncompleteLength: 0, maximumLength: 4096, completion:{(data, context, flag, error) in
            if let error = error {
                NSLog("\(#function), \(error)")
            } else {
                if let data = data {
                    let bytes:[UInt8] = [UInt8](data)
                    var retname: String = ""
                    if(bytes.count > 0){
                        switch bytes[0] {
                        case 0x06: //正常終了
                            retname = "ACK"
                        case 0x18: //異常終了
                            retname = "CAN"
                        case 0x17: //ニアエンプティ
                            retname = "CAN"
                        case 0x15: //通信異常
                            retname = "NAK"
                        case 0x13: //セットはずれ
                            retname = "DC3"
                        case 0x1A: //動作中
                            retname = "SUB"
                        case 0x14: //放出可動作中
                            retname = "DC4"
                        case 0x01: //計数中
                            retname = "SOH"
                        case 0x19: //計数停止中
                            retname = "EM"
                        case 0x07: //動作不可
                            retname = "BEL"
                        case 0x12: //抜き取り待ち
                            retname = "DC2"
                        case 0x10: //レスポンスの先頭
                            retname = "DLE"
                        default:
                            retname = ""
                        }
                        //2バイト以上のリターンからの編集
                        if(bytes.count > 1){
                            retname = self.bytetohexstr(inbyte: bytes)
                            print("16進電文:" + retname)
                        }
                    }
                    print(retname)//<Add 20211108>
                    print("Flag:" + flag.description)
                    //print("取得内容:" + retname)
                    strRtn = retname
                    
                    DispatchQueue.main.async {
                        self.cntv.dispitems.chargerstatus = retname
                    }
                    //下に移動?
                    semaphore.signal()
                }
                else {
                    NSLog("receiveMessage data nil")
                }
            }
            //semaphore.signal()
        })
        
        semaphore.wait()
        
        return strRtn
    }
    //</Add 20211115 V1.16>
    
    //seisa受信
    //https://www.radical-dreamer.com/programming/raspberry-pi-bme280-client/#toc10
    func recv_seisa(connection: NWConnection) -> String {
        var strRtn: String = ""
        
        let semaphore = DispatchSemaphore(value: 0)
        connection.receive(minimumIncompleteLength: 0, maximumLength: 4096, completion:{(data, context, flag, error) in
            if let error = error {
                NSLog("\(#function), \(error)")
            } else {
                if let data = data {
                    let bytes:[UInt8] = [UInt8](data)
                    var retname: String = ""
                    if(bytes.count > 0){
                        switch bytes[0] {
                        case 0x06: //正常終了
                            retname = "ACK"
                        case 0x18: //異常終了
                            retname = "CAN"
                        case 0x17: //ニアエンプティ
                            retname = "CAN"
                        case 0x15: //通信異常
                            retname = "NAK"
                        case 0x13: //セットはずれ
                            retname = "DC3"
                        case 0x1A: //動作中
                            retname = "SUB"
                        case 0x14: //放出可動作中
                            retname = "DC4"
                        case 0x01: //計数中
                            retname = "SOH"
                        case 0x19: //計数停止中
                            retname = "EM"
                        case 0x07: //動作不可
                            retname = "BEL"
                        case 0x12: //抜き取り待ち
                            retname = "DC2"
                        case 0x10: //レスポンスの先頭
                            retname = "DLE"
                        default:
                            retname = ""
                        }
                        //2バイト以上のリターンからの編集
                        if(bytes.count > 1){
                            retname = self.bytetohexstr(inbyte: bytes)
                            print("16進電文:" + retname)
                        }
                    }
                    print("seisaFlag:" + flag.description)
                    strRtn = retname
                    
                    DispatchQueue.main.async {
                        self.cntv.dispitems.chargerstatus = retname
                    }
                    //下に移動?
                    semaphore.signal()
                }
                else {
                    NSLog("receiveMessage data nil")
                }
            }
            //semaphore.signal()
        })
        
        semaphore.wait()
        
        return strRtn
    }
    
    func recv_read(connection: NWConnection) {
        let semaphore = DispatchSemaphore(value: 0)
        //connection.receive(minimumIncompleteLength: 0, maximumLength: 65535, completion:{(data, context, flag, error) in
        connection.receive(minimumIncompleteLength: 0, maximumLength: 256, completion:{(data, context, flag, error) in
            if let error = error {
                NSLog("\(#function), \(error)")
            } else {
                if let data = data {
                    let bytes:[UInt8] = [UInt8](data)
                    var retname: String = ""
                    if(bytes.count > 0){
                        switch bytes[0] {
                        case 0x06: //正常終了
                            retname = "ACK"
                        case 0x18: //異常終了
                            retname = "CAN"
                        case 0x17: //ニアエンプティ
                            retname = "CAN"
                        case 0x15: //通信異常
                            retname = "NAK"
                        case 0x13: //セットはずれ
                            retname = "DC3"
                        case 0x1A: //動作中
                            retname = "SUB"
                        case 0x14: //放出可動作中
                            retname = "DC4"
                        case 0x01: //計数中
                            retname = "SOH"
                        case 0x19: //計数停止中
                            retname = "EM"
                        case 0x07: //動作不可
                            retname = "BEL"
                        case 0x12: //抜き取り待ち
                            retname = "DC2"
                        case 0x10: //レスポンスの先頭
                            retname = "DLE"
                        default:
                            retname = ""
                        }
                        //2バイト以上のリターンからの編集
                        if(bytes.count > 1){
                            retname = self.bytetohexstr(inbyte: bytes)
                            print("16進電文:" + retname)
                            retname = self.KEISUResponse(strHx: retname)
                        }
                    }
                    print("Flag:" + flag.description)
                    print("取得内容:" + retname)
                    
                    DispatchQueue.main.async {
                        self.cntv.dispitems.chargerstatus = retname
                    }
                    
                    var blnRead: Bool = false
                    if (bytes.count == 1 && bytes[0] == 0x10){
                        blnRead = true
                    }
                    if (bytes.count > 1 && bytes.count < 44){ //計数リードのレスポンス長は45byte(BCC含む)
                        blnRead = true
                    }
                    if (blnRead){
                        usleep(500)
                        self.recv_read(connection: connection)
                    }
                    //下に移動?
                    semaphore.signal()
                }
                else {
                    NSLog("receiveMessage data nil")
                }
            }
            //semaphore.signal()
        })
        
        semaphore.wait()
    }
    //受信
    func recv(connection: NWConnection) {
        let semaphore = DispatchSemaphore(value: 0)
        connection.receive(minimumIncompleteLength: 0, maximumLength: 65535, completion:{(data, context, flag, error) in
            if let error = error {
                NSLog("\(#function), \(error)")
            } else {
                if let data = data {
                    let text:String = String(data: data, encoding: .utf8)!
                    let words = text.components(separatedBy: ",")
                    DispatchQueue.main.async {
                        self.cntv.dispitems.announce = ":\(words[0].trimmingCharacters(in: .whitespacesAndNewlines))"
                    }
                    semaphore.signal()
                }
                else {
                    NSLog("receiveMessage data nil")
                }
            }
        })
        
        semaphore.wait()
    }
    //切断
    func disconnect(connection: NWConnection)
    {
        connection.cancel()
    }
    //接続
    func tcpconnect(host: String, port: String) -> NWConnection
    {
        let t_host = NWEndpoint.Host(host)
        let t_port = NWEndpoint.Port(port)
        let connection : NWConnection
        let semaphore = DispatchSemaphore(value: 0)
        
        connection = NWConnection(host: t_host, port: t_port!, using: .tcp)
        
        connection.stateUpdateHandler = { (newState) in
            switch newState {
            case .ready:
                //NSLog("Ready to send")
                //下に移動？
                semaphore.signal()//20210826
            case .waiting(let error):
                NSLog("waiting \(#function), \(error)")
            case .failed(let error):
                NSLog("failed \(#function), \(error)")
            case .setup: break
            case .cancelled: break
            case .preparing: break
            @unknown default:
                fatalError("Illegal state")//プログラムを強制終了させる関数
            }
            //↑State毎にsemaphore解除を行うべき
            //semaphore.signal()//20210826
        }
        
        let queue = DispatchQueue(label: "temphum")
        connection.start(queue:queue)
        
        semaphore.wait()
        
        return connection
    }
    
    //釣り銭機への送信
    //ENQ送信
    func enq_telegram_get(host:String, port:String) -> String
    {
        var strRtn: String = ""
        
        let connection : NWConnection
        //let addr = sender.userInfo as! Dictionary<String, String>
        //let host = host
        //let port = port
        //doで囲んでいるのは無駄かも
        do {
            connection = tcpconnect(host: host, port: port)
            //if connection.state == .ready {
            
            //}
            let enqbytes: [UInt8] = [0x05]
            send(connection: connection, sendbytes: enqbytes)
            strRtn = recv_enq(connection: connection)
            disconnect(connection: connection)
        } catch  {
            print("Error: \(error)")
        }
        //connection = connect(host: host, port: port)
        //let enqbytes: [UInt8] = [0x05]
        //send(connection: connection, sendbytes: enqbytes)
        //recv(connection: connection)
        //disconnect(connection: connection)
        
        return strRtn
    }
    //EOT送信
    func eot_telegram_get(host:String, port:String) -> String
    {
        var strRtn: String = ""
        
        let connection : NWConnection
        //doで囲んでいるのは無駄かも
        do {
            connection = tcpconnect(host: host, port: port)
            let enqbytes: [UInt8] = [0x04]
            send(connection: connection, sendbytes: enqbytes)
            strRtn = recv_enq(connection: connection)
            disconnect(connection: connection)
        } catch  {
            print("Error: \(error)")
        }
        
        return strRtn
    }
    //精査送信
    func seisa_telegram_get(host:String, port:String,delay:Int) -> String
    {
        var strRtn: String = ""
        
        let connection : NWConnection
        
        let stx: UInt8 = 0x02
        let dc1: UInt8 = 0x11
        let dh1: UInt8 = 0x32 //精査
        let L0: UInt8 = 0x30
        let L1: UInt8 = 0x30
        let etx: UInt8 = 0x03
        var CMD:[UInt8] = [stx, dc1, dh1, L0, L1, etx]
        var bcc:[UInt8] = [0x00]
        for i in 1..<CMD.count{ //パリティ計算(２バイト目から)
            bcc[0] ^= CMD[i]
        }
        CMD.append(bcc[0])
        
        //doで囲んでいるのは無駄かも
        do {
            connection = tcpconnect(host: host, port: port)
            send(connection: connection, sendbytes: CMD)
            let ddelay = Double(delay)*0.1
            Thread.sleep(forTimeInterval: 0.5 + ddelay)
            //Thread.sleep(forTimeInterval: 0.05 + ddelay)//<エラー発生デバッグ用 20211108>
            strRtn = recv_seisa(connection: connection)
            //<Add 20211115 V1.16>
            var iEnd: Int = 0
            while strRtn.count < 150 { //366 より 155 の方がいい？
                Thread.sleep(forTimeInterval: 0.1)
                strRtn += recv_seisa(connection: connection)
                
                iEnd += 1
                if iEnd > 5 { //<Upd 20220210 />5->20
                    break
                }
            }
            //</Add 20211115 V1.16>
            disconnect(connection: connection)
        } catch  {
            print("Error: \(error)")
        }
        
        return strRtn
    }
    //計数スタート送信
    func keisustart_telegram_get(host:String, port:String) -> String
    {
        var strRtn: String = ""
        
        let connection : NWConnection
        
        let stx: UInt8 = 0x02
        let dc1: UInt8 = 0x11
        let dh1: UInt8 = 0x45 //計数開始
        let L0: UInt8 = 0x30
        let L1: UInt8 = 0x30
        let etx: UInt8 = 0x03
        var CMD:[UInt8] = [stx, dc1, dh1, L0, L1, etx]
        var bcc:[UInt8] = [0x00]
        for i in 1..<CMD.count{ //パリティ計算(２バイト目から)
            bcc[0] ^= CMD[i]
        }
        CMD.append(bcc[0])
        
        //doで囲んでいるのは無駄かも
        do {
            connection = tcpconnect(host: host, port: port)
            send(connection: connection, sendbytes: CMD)
            Thread.sleep(forTimeInterval: 0.1)//<Add 0211120 コマンドのすっぽ抜け回避？ V1.18 />
            strRtn = recv_enq(connection: connection)
            disconnect(connection: connection)
        } catch  {
            print("Error: \(error)")
        }
        
        return strRtn
    }
    //計数リード送信
    func keisuread_telegram_get(host:String, port:String, delay:Int) -> String
    {
        var strRtn: String = ""
        
        let connection : NWConnection
        
        let stx: UInt8 = 0x02
        let dc1: UInt8 = 0x11
        let dh1: UInt8 = 0x41 //計数リード
        let L0: UInt8 = 0x30
        let L1: UInt8 = 0x30
        let etx: UInt8 = 0x03
        var CMD:[UInt8] = [stx, dc1, dh1, L0, L1, etx]
        var bcc:[UInt8] = [0x00]
        for i in 1..<CMD.count{ //パリティ計算(２バイト目から)
            bcc[0] ^= CMD[i]
        }
        CMD.append(bcc[0])
        
        //doで囲んでいるのは無駄かも
        do {
            connection = tcpconnect(host: host, port: port)
            send(connection: connection, sendbytes: CMD)

            let ddelay = Double(delay)*0.1
            Thread.sleep(forTimeInterval: 0.5 + ddelay)
            //Thread.sleep(forTimeInterval: 0.05 + ddelay)//<エラー発生デバッグ用 20211108>
            var iEnd: Int = 0
            strRtn = recv_keisuread(connection: connection)
            while strRtn.count < 123 {
                Thread.sleep(forTimeInterval: 0.1)
                strRtn += recv_keisuread(connection: connection)
                
                iEnd += 1
                if iEnd > 5 { //<Upd 20220210 />5->20
                    break
                }
            }
            strRtn = KEISUResponse(strHx: strRtn)//１秒以上掛かって読み切らなかったら""を返している
            
            disconnect(connection: connection)
        } catch  {
            print("Error: \(error)")
        }
        
        return strRtn
    }
    //計数リード送信(同期型)
    func keisuread_telegram_getsync(host:String, port:String) -> String
    {
        var strRtn: String = ""
        
        //let connection : NWConnection
        
        let stx: UInt8 = 0x02
        let dc1: UInt8 = 0x11
        let dh1: UInt8 = 0x41 //計数リード
        let L0: UInt8 = 0x30
        let L1: UInt8 = 0x30
        let etx: UInt8 = 0x03
        var CMD:[UInt8] = [stx, dc1, dh1, L0, L1, etx]
        var bcc:[UInt8] = [0x00]
        for i in 1..<CMD.count{ //パリティ計算(２バイト目から)
            bcc[0] ^= CMD[i]
        }
        CMD.append(bcc[0])
        
        //doで囲んでいるのは無駄かも
        do {
            let tcpsock = SyncConnection()
            tcpsock.connect(host: host, port: port)
            let res: [UInt8] = tcpsock.sendCommand(sendbytes: CMD)
            var retname: String = ""
            if(res.count > 1){
                retname = self.bytetohexstr(inbyte: res)
                print("16進電文:" + retname)
                retname = self.KEISUResponse(strHx: retname)
            }
            print("取得内容:" + retname)
            strRtn = retname
            DispatchQueue.main.async {
                self.cntv.dispitems.chargerstatus = retname
            }
        } catch {
            print("Error: \(error)")
        }
        
        return strRtn
    }
    
    //計数終了送信(計数停止中のみコマンドを受け付ける)
    func keisuend_telegram_get(host:String, port:String) -> String
    {
        var strRtn: String = ""
        
        let connection : NWConnection
        
        let stx: UInt8 = 0x02
        let dc1: UInt8 = 0x11
        let dh1: UInt8 = 0x46 //計数終了
        let L0: UInt8 = 0x30
        let L1: UInt8 = 0x30
        let etx: UInt8 = 0x03
        var CMD:[UInt8] = [stx, dc1, dh1, L0, L1, etx]
        var bcc:[UInt8] = [0x00]
        for i in 1..<CMD.count{ //パリティ計算(２バイト目から)
            bcc[0] ^= CMD[i]
        }
        CMD.append(bcc[0])
        
        //doで囲んでいるのは無駄かも
        do {
            connection = tcpconnect(host: host, port: port)
            send(connection: connection, sendbytes: CMD)//釣銭機へコマンドの送信
            Thread.sleep(forTimeInterval: 0.1)//<Add 0211120 コマンドのすっぽ抜け回避？ V1.18 />
            strRtn = recv_enq(connection: connection) //中で釣り銭機から受信した結果の編集
            disconnect(connection: connection)
        } catch  {
            print("Error: \(error)")
        }
        
        return strRtn
    }
    //計数停止送信
    //計数処理の停止を予約します
    //予約後、以下の条件を全て満たすと、計数停止中となります。
    //・投入口／挿入口の媒体を全て計数した。
    //・紙幣化セットがフルではない
    //・リジェクト媒体の抜き取り待ち中ではない
    //・計数動作中（SOH時）のみコマンドが有効です
    //・計数停止中になると、媒体を投入口／納入口に入れても計数動作を開始しません。（計数動作禁止）
    func keisustop_telegram_get(host:String, port:String) -> String
    {
        var strRtn: String = ""
        
        let connection : NWConnection
        
        let stx: UInt8 = 0x02
        let dc1: UInt8 = 0x11
        let dh1: UInt8 = 0x47 //計数停止
        let L0: UInt8 = 0x30
        let L1: UInt8 = 0x30
        let etx: UInt8 = 0x03
        var CMD:[UInt8] = [stx, dc1, dh1, L0, L1, etx]
        var bcc:[UInt8] = [0x00]
        for i in 1..<CMD.count{ //パリティ計算(２バイト目から)
            bcc[0] ^= CMD[i]
        }
        CMD.append(bcc[0])
        
        //doで囲んでいるのは無駄かも
        do {
            connection = tcpconnect(host: host, port: port)
            send(connection: connection, sendbytes: CMD)
            Thread.sleep(forTimeInterval: 0.1)//<Add 0211120 コマンドのすっぽ抜け回避？ V1.18 />
            strRtn = recv_enq(connection: connection)
            disconnect(connection: connection)
        } catch  {
            print("Error: \(error)")
        }
        
        return strRtn
    }
    //計数再開送信
    func keisurestart_telegram_get(host:String, port:String) -> String
    {
        var strRtn: String = ""
        
        let connection : NWConnection
        
        let stx: UInt8 = 0x02
        let dc1: UInt8 = 0x11
        let dh1: UInt8 = 0x48 //計数再開
        let L0: UInt8 = 0x30
        let L1: UInt8 = 0x30
        let etx: UInt8 = 0x03
        var CMD:[UInt8] = [stx, dc1, dh1, L0, L1, etx]
        var bcc:[UInt8] = [0x00]
        for i in 1..<CMD.count{ //パリティ計算(２バイト目から)
            bcc[0] ^= CMD[i]
        }
        CMD.append(bcc[0])
        
        //doで囲んでいるのは無駄かも
        do {
            connection = tcpconnect(host: host, port: port)
            send(connection: connection, sendbytes: CMD)
            strRtn = recv_enq(connection: connection)
            disconnect(connection: connection)
        } catch  {
            print("Error: \(error)")
        }
        
        return strRtn
    }
    //リセット送信
    func reset_telegram_get(host:String, port:String) -> String
    {
        var strRtn: String = ""
        
        let connection : NWConnection
        
        let stx: UInt8 = 0x02
        let dc1: UInt8 = 0x11
        let dh1: UInt8 = 0x30 //reset
        let L0: UInt8 = 0x30
        let L1: UInt8 = 0x30
        let etx: UInt8 = 0x03
        var CMD:[UInt8] = [stx, dc1, dh1, L0, L1, etx]
        var bcc:[UInt8] = [0x00]
        for i in 1..<CMD.count{ //パリティ計算(２バイト目から)
            bcc[0] ^= CMD[i]
        }
        CMD.append(bcc[0])
        
        //doで囲んでいるのは無駄かも
        do {
            connection = tcpconnect(host: host, port: port)
            send(connection: connection, sendbytes: CMD)
            strRtn = recv_enq(connection: connection)
            disconnect(connection: connection)
        } catch  {
            print("Error: \(error)")
        }
        
        return strRtn
    }
    //釣銭放出指示送信
    func payout6_telegram_get(host:String, port:String, amount:String) -> String
    {
        var strRtn: String = ""
        
        let connection : NWConnection
        
        let stx: UInt8 = 0x02
        let dc1: UInt8 = 0x11
        let dh1: UInt8 = 0x31 //金額指定放出
        let L0: UInt8 = 0x30
        let L1: UInt8 = 0x36 //データ部６桁
        var D0: UInt8 = 0x00
        var D1: UInt8 = 0x00
        var D2: UInt8 = 0x00
        var D3: UInt8 = 0x00
        var D4: UInt8 = 0x00
        var D5: UInt8 = 0x00
        let etx: UInt8 = 0x03
        
        let substr : (String, Int, Int) -> String = { text, from, length in
            let to = text.index(text.startIndex, offsetBy:from + length)
            let from = text.index(text.startIndex, offsetBy:from)
            return String(text[from...to])
        }
        let amnt: Int = Int(amount) ?? 0
        let amount6: String = String(format: "%06d", amnt)
        let cd0 = substr(amount6, 0, 0)
        var ach:[UInt8] = Array(cd0.utf8)
        D0 = ach[0]
        let cd1 = substr(amount6, 1, 0)
        ach = Array(cd1.utf8)
        D1 = ach[0]
        let cd2 = substr(amount6, 2, 0)
        ach = Array(cd2.utf8)
        D2 = ach[0]
        let cd3 = substr(amount6, 3, 0)
        ach = Array(cd3.utf8)
        D3 = ach[0]
        let cd4 = substr(amount6, 4, 0)
        ach = Array(cd4.utf8)
        D4 = ach[0]
        let cd5 = substr(amount6, 5, 0)
        ach = Array(cd5.utf8)
        D5 = ach[0]
        
        
        var CMD:[UInt8] = [stx, dc1, dh1, L0, L1, D0, D1, D2, D3, D4, D5, etx]
        var bcc:[UInt8] = [0x00]
        for i in 1..<CMD.count{ //パリティ計算(２バイト目から)
            bcc[0] ^= CMD[i]
        }
        CMD.append(bcc[0])
        
        //doで囲んでいるのは無駄かも
        do {
            connection = tcpconnect(host: host, port: port)
            send(connection: connection, sendbytes: CMD)
            strRtn = recv_enq(connection: connection)
            disconnect(connection: connection)
        } catch  {
            print("Error: \(error)")
        }
        
        return strRtn
    }
    
    //<Add 20210914 ver1.5>
    //釣銭放出枚数指定(3桁)送信
    func payout_telegram_get(host:String, port:String, pieces:String) -> String
    {
        var strRtn: String = ""
        
        let connection : NWConnection
        
        let stx: UInt8 = 0x02
        let dc1: UInt8 = 0x11
        let dh1: UInt8 = 0x35 //枚数指定放出
        let L0: UInt8 = 0x31
        let L1: UInt8 = 0x3E //データ部30桁
        var DR: [UInt8] = [0x00]
        let etx: UInt8 = 0x03
        
        //文字照部分抜き出し関数
        let substr : (String, Int, Int) -> String = { text, from, length in
            let to = text.index(text.startIndex, offsetBy:from + length)
            let from = text.index(text.startIndex, offsetBy:from)
            return String(text[from...to])
        }
        
        let kinsh = ["2000円", "10000円", "5000円", "1000円", "500円", "100円", "50円", "10円", "5円", "1円"]
        //piecesをJsonに変換して金種ごとの枚数を取得する
        let personalData: Data =  pieces.data(using: String.Encoding.utf8)!
        //print(pieces)
        
        do {
            // パースする
            var items = try JSONSerialization.jsonObject(with: personalData) as! Dictionary<String, Any>
            DR.removeAll()
            for i in 0..<kinsh.count {
                let maisu = items[kinsh[i]] as? String ?? "000"
                let cd0 = substr(maisu, 0, 0)
                var ach:[UInt8] = Array(cd0.utf8)
                DR.append(ach[0])
                let cd1 = substr(maisu, 1, 0)
                ach = Array(cd1.utf8)
                DR.append(ach[0])
                let cd2 = substr(maisu, 2, 0)
                ach = Array(cd2.utf8)
                DR.append(ach[0])
            }
        } catch {
            print(error)
        }
        
        var CMD:[UInt8] = [stx, dc1, dh1, L0, L1]
        for x in 0...DR.count-1{
            CMD.append(DR[x])
        }
        CMD.append(etx)
        
        var bcc:[UInt8] = [0x00]
        for i in 1..<CMD.count{ //パリティ計算(２バイト目から)
            bcc[0] ^= CMD[i]
        }
        CMD.append(bcc[0])
        
        //doで囲んでいるのは無駄かも
        do {
            connection = tcpconnect(host: host, port: port)
            send(connection: connection, sendbytes: CMD)
            strRtn = recv_enq(connection: connection)
            disconnect(connection: connection)
        } catch  {
            print("Error: \(error)")
        }
        
        return strRtn
    }
    //釣銭放出枚数指定(２桁)送信
    func payout_telegram_get2(host:String, port:String, pieces:String) -> String
    {
        var strRtn: String = ""
        
        let connection : NWConnection
        
        let stx: UInt8 = 0x02
        let dc1: UInt8 = 0x11
        let dh1: UInt8 = 0x35 //枚数指定放出
        let L0: UInt8 = 0x31
        let L1: UInt8 = 0x34 //データ部30桁
        var DR: [UInt8] = [0x00]
        let etx: UInt8 = 0x03
        
        //文字照部分抜き出し関数
        let substr : (String, Int, Int) -> String = { text, from, length in
            let to = text.index(text.startIndex, offsetBy:from + length)
            let from = text.index(text.startIndex, offsetBy:from)
            return String(text[from...to])
        }
        
        let kinsh = ["2000円", "10000円", "5000円", "1000円", "500円", "100円", "50円", "10円", "5円", "1円"]
        //piecesをJsonに変換して金種ごとの枚数を取得する
        let personalData: Data =  pieces.data(using: String.Encoding.utf8)!
        
        do {
            // パースする
            var items = try JSONSerialization.jsonObject(with: personalData) as! Dictionary<String, Any>
            DR.removeAll()
            for i in 0..<kinsh.count {
                let maisu = items[kinsh[i]] as? String ?? "000"
                let cd0 = substr(maisu, 1, 0)
                var ach:[UInt8] = Array(cd0.utf8)
                DR.append(ach[0])
                let cd1 = substr(maisu, 2, 0)
                ach = Array(cd1.utf8)
                DR.append(ach[0])
                //                let cd2 = substr(maisu, 2, 0)
                //                ach = Array(cd2.utf8)
                //                DR.append(ach[0])
            }
        } catch {
            print(error)
        }
        
        var CMD:[UInt8] = [stx, dc1, dh1, L0, L1]
        for x in 0...DR.count-1{
            CMD.append(DR[x])
        }
        CMD.append(etx)
        
        var bcc:[UInt8] = [0x00]
        for i in 1..<CMD.count{ //パリティ計算(２バイト目から)
            bcc[0] ^= CMD[i]
        }
        CMD.append(bcc[0])
        
        //doで囲んでいるのは無駄かも
        do {
            connection = tcpconnect(host: host, port: port)
            send(connection: connection, sendbytes: CMD)
            strRtn = recv_enq(connection: connection)
            disconnect(connection: connection)
        } catch  {
            print("Error: \(error)")
        }
        
        return strRtn
    }
    //</Add 20210914 ver1.5>
    
    func chargeable(chargeamount: Int)->Bool {
        var blnCan = true
        //<Add 20210914 ver1.5>
        if chargeamount == 0 {
            return blnCan
        }
        //</Add 20210914 ver1.5>
        var charge: Int = chargeamount
        var transtring = seisa_telegram_get(host: cntv.dispitems.changerip, port:cntv.dispitems.changerport, delay: 0)
        transtring = SeisaResponse(strHx: transtring)
        //<Add 20211112 ver1.16>
        //<SeisaResponseが空で返ってきたら、seisa_telegram_getを繰り返す処理を追加>
        var iEnd :Int = 1
        while (transtring == ""){
            Thread.sleep(forTimeInterval: 0.1)
            transtring = seisa_telegram_get(host: cntv.dispitems.changerip, port:cntv.dispitems.changerport, delay: iEnd)
            transtring = SeisaResponse(strHx: transtring)
            iEnd += 1
            if (iEnd > 4){
                break
            }
        }
        //</Add 20211112 ver1.16>
        //<Add 20210914 ver1.5>
        if transtring == "" {
            blnCan = false
            return blnCan
        }
        //</Add 20210914 ver1.5>
        let tranData:Data = transtring.data(using: String.Encoding.utf8)!
        do {
            let dic = try JSONSerialization.jsonObject(with: tranData) as! Dictionary<String, String>
            let kinshuh: [Int] = [10000, 5000, 1000]
            let kinshuk: [Int] = [500, 100, 50, 10, 5, 1]
            var intMaisu: Int
            var intSeimai: Int
            //各金種での判定
            //紙幣と硬貨間で代替えは行われない
            //紙幣での判定
            for idx in 0...kinshuh.count-1{
                intMaisu = charge / kinshuh[idx]
                let kinen = String(kinshuh[idx]) + "円"
                intSeimai = Int(dic[kinen] ?? "0") ?? 0
                
                if (intMaisu > 0){
                    if (intMaisu <= intSeimai){
                        charge = charge - (intMaisu * kinshuh[idx])
                    } else {
                        if (idx+1 == kinshuh.count) {
                            //紙幣から硬貨の代替えはしないので、エラー
                            return false
                        }
                        
                        var chgkari = charge - (intSeimai * kinshuh[idx])
                        var iMai = chgkari / kinshuh[idx+1]
                        let kinkari = String(kinshuh[idx+1]) + "円"
                        let iSeimai = Int(dic[kinkari] ?? "0") ?? 0
                        if (iMai > iSeimai){
                            //２つ目の金種でも足りなければエラー
                            return false
                        }
                        
                        charge = charge - (intSeimai * kinshuh[idx])
                    }
                }
            }
            //硬貨での判定
            for idx in 0...kinshuk.count-1{
                intMaisu = charge / kinshuk[idx]
                let kinen = String(kinshuk[idx]) + "円"
                intSeimai = Int(dic[kinen] ?? "0") ?? 0
                
                if (intMaisu > 0){
                    if (intMaisu <= intSeimai){
                        charge = charge - (intMaisu * kinshuk[idx])
                    } else {
                        if (idx+1 == kinshuk.count) {
                            //1円以下の硬貨はないので、エラー
                            return false
                        }
                        
                        var chgkari = charge - (intSeimai * kinshuk[idx])
                        var iMai = chgkari / kinshuk[idx+1]
                        let kinkari = String(kinshuk[idx+1]) + "円"
                        let iSeimai = Int(dic[kinkari] ?? "0") ?? 0
                        if (iMai > iSeimai){
                            //２つ目の金種でも足りなければエラー
                            return false
                        }
                        
                        charge = charge - (intSeimai * kinshuk[idx])
                    }
                }
            }
            
        } catch {
            print(error)
        }
        
        if (charge > 0){
            blnCan = false
        }
        return blnCan
    }
    
    //精査時のレスポンスをjson変換する
    func SeisaResponse(strHx: String)->String
    {
        let aHex: [Substring] = strHx.split(separator: "h");
        var dic = Dictionary<String, String>()
        var amount:Int = 0
        var jstr: String = ""
        
        if (aHex.count < 45) {
            return ""
        }
        //<20210914 包装硬貨ありフォーマットに対応していない>
        
        var strMai: String = ""
        let iTop: Int = 4
        strMai = String(aHex[iTop+0].suffix(1))
        strMai += String(aHex[iTop+1].suffix(1))
        strMai += String(aHex[iTop+2].suffix(1))
        dic["2000円"] = strMai
        amount += 2000 * (Int(strMai) ?? 0)
        
        strMai = String(aHex[iTop+3].suffix(1))
        strMai += String(aHex[iTop+4].suffix(1))
        strMai += String(aHex[iTop+5].suffix(1))
        dic["10000円"] = strMai
        amount += 10000 * (Int(strMai) ?? 0)
        
        strMai = String(aHex[iTop+6].suffix(1))
        strMai += String(aHex[iTop+7].suffix(1))
        strMai += String(aHex[iTop+8].suffix(1))
        dic["5000円"] = strMai
        amount += 5000 * (Int(strMai) ?? 0)
        
        strMai = String(aHex[iTop+9].suffix(1))
        strMai += String(aHex[iTop+10].suffix(1))
        strMai += String(aHex[iTop+11].suffix(1))
        dic["1000円"] = strMai
        amount += 1000 * (Int(strMai) ?? 0)
        
        strMai = String(aHex[iTop+12].suffix(1))
        strMai += String(aHex[iTop+13].suffix(1))
        strMai += String(aHex[iTop+14].suffix(1))
        dic["C2000円"] = strMai
        amount += 2000 * (Int(strMai) ?? 0)
        
        strMai = String(aHex[iTop+15].suffix(1))
        strMai += String(aHex[iTop+16].suffix(1))
        strMai += String(aHex[iTop+17].suffix(1))
        dic["C10000円"] = strMai
        amount += 10000 * (Int(strMai) ?? 0)
        
        strMai = String(aHex[iTop+18].suffix(1))
        strMai += String(aHex[iTop+19].suffix(1))
        strMai += String(aHex[iTop+20].suffix(1))
        dic["C5000円"] = strMai
        amount += 5000 * (Int(strMai) ?? 0)
        
        strMai = String(aHex[iTop+21].suffix(1))
        strMai += String(aHex[iTop+22].suffix(1))
        strMai += String(aHex[iTop+23].suffix(1))
        dic["C1000円"] = strMai
        amount += 1000 * (Int(strMai) ?? 0)
        
        strMai = String(aHex[iTop+24].suffix(1))
        strMai += String(aHex[iTop+25].suffix(1))
        strMai += String(aHex[iTop+26].suffix(1))
        dic["500円"] = strMai
        amount += 500 * (Int(strMai) ?? 0)
        
        strMai = String(aHex[iTop+27].suffix(1))
        strMai += String(aHex[iTop+28].suffix(1))
        strMai += String(aHex[iTop+29].suffix(1))
        dic["100円"] = strMai
        amount += 100 * (Int(strMai) ?? 0)
        
        strMai = String(aHex[iTop+30].suffix(1))
        strMai += String(aHex[iTop+31].suffix(1))
        strMai += String(aHex[iTop+32].suffix(1))
        dic["50円"] = strMai
        amount += 50 * (Int(strMai) ?? 0)
        
        strMai = String(aHex[iTop+33].suffix(1))
        strMai += String(aHex[iTop+34].suffix(1))
        strMai += String(aHex[iTop+35].suffix(1))
        dic["10円"] = strMai
        amount += 10 * (Int(strMai) ?? 0)
        
        strMai = String(aHex[iTop+36].suffix(1))
        strMai += String(aHex[iTop+37].suffix(1))
        strMai += String(aHex[iTop+38].suffix(1))
        dic["5円"] = strMai
        amount += 5 * (Int(strMai) ?? 0)
        
        strMai = String(aHex[iTop+39].suffix(1))
        strMai += String(aHex[iTop+40].suffix(1))
        strMai += String(aHex[iTop+41].suffix(1))
        dic["1円"] = strMai
        amount += Int(strMai) ?? 0
        
        dic["合計金額"] = String(amount)
        
        do {
            // DictionaryをJSONデータに変換
            let jsonData = try JSONSerialization.data(withJSONObject: dic)
            // JSONデータを文字列に変換
            jstr = String(bytes: jsonData, encoding: .utf8)!
            print(jstr)
        } catch (let e) {
            print(e)
        }
        return jstr
    }
}

/*
 同期型tcp通信クラス
 */
class SyncConnection: NSObject, StreamDelegate {
    //let ServerAddress: CFString =  NSString(string: "xxx.xxx.xxx.xxx") //IPアドレスを指定
    //let serverPort: UInt32 = xxxx //開放するポートを指定
    
    private var inputStream : InputStream!
    private var outputStream: OutputStream!
    
    //**
    /* @brief サーバーとの接続を確立する
     */
    func connect(host: String, port: String){
        print("connecting.....")
        
        var readStream : Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?
        
        let ServerAddress: CFString =  NSString(string: host)
        let serverPort: UInt32 = UInt32(port) ?? 0
        //CFStreamCreatePairWithSocketToHost(nil, self.ServerAddress, self.serverPort, &readStream, &writeStream)
        CFStreamCreatePairWithSocketToHost(nil, ServerAddress, serverPort, &readStream, &writeStream)
        
        self.inputStream  = readStream!.takeRetainedValue()
        self.outputStream = writeStream!.takeRetainedValue()
        
        self.inputStream.delegate  = self
        self.outputStream.delegate = self
        
        self.inputStream.schedule(in: RunLoop.current, forMode: RunLoop.Mode.default)
        self.outputStream.schedule(in: RunLoop.current, forMode: RunLoop.Mode.default)
        
        self.inputStream.open()
        self.outputStream.open()
        
        print("connect success!!")
    }
    
    //**
    /* @brief inputStream/outputStreamに何かしらのイベントが起きたら起動してくれる関数
     *        今回の場合では、同期型なのでoutputStreamの時しか起動してくれない
     */
    func stream(_ stream:Stream, handle eventCode : Stream.Event){
        //print(stream)
    }
    
    //**
    /* @brief サーバーにコマンド文字列を送信する関数
     */
    func sendCommand(sendbytes:[UInt8])->[UInt8] {
        //var ccommand = command.data(using: String.Encoding.utf8, allowLossyConversion: false)!
        //let text = ccommand.withUnsafeMutableBytes{ bytes in return String(bytesNoCopy: bytes, length: ccommand.count, encoding: String.Encoding.utf8, freeWhenDone: false)!}
        
        self.outputStream.write(UnsafePointer(sendbytes), maxLength: sendbytes.count)
        //print("Send: \(command)")
        
        self.outputStream.close()
        self.outputStream.remove(from: RunLoop.current, forMode: RunLoop.Mode.default)
        
        while(!inputStream.hasBytesAvailable){}
        let bufferSize = 1024
        var buffer = Array<UInt8>(repeating: 0, count: bufferSize)
        let bytesRead = inputStream.read(&buffer, maxLength: bufferSize)
        if (bytesRead >= 0) {
            let read = String(bytes: buffer, encoding: String.Encoding.utf8)!
            print("Receive: \(read)")
        }
        self.inputStream.close()
        self.inputStream.remove(from: RunLoop.current, forMode: RunLoop.Mode.default)
        
        return buffer
    }
}
