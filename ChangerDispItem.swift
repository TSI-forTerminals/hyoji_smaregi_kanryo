//
//  ChangerDispItem.swift
//  smaregi_kanryo_hyoji
//
//  Created by 城川一理 on 2021/08/08.
//

import SwiftUI

class DispItems: ObservableObject {
    @Published var announce = "" //"いらっしゃいませ" //アナウンス
    @Published var billingamount = "0" //請求金額
    @Published var depositamount = "0" //投入金額
    @Published var minusamount = "0" //不足金額
    @Published var chargeamount = "0" //おつり
    @Published var chargerstatus = "0" //精算機の状態
    @Published var confirmstatus = "0" //確認ボタンの状態　0:有効化前 1:有効状態 2:確認状態 3:取消押下
    @Published var customercode = "" //会員コード
    @Published var customername = "" //会員名
    @Published var jusinOK = "" //受信OK<Add 20210927 V1.8? />

    //中継サーバーのアドレス
    @Published var relayip: String{
        didSet{
            //プロパティ設定領域への保存
            UserDefaults.standard.set(relayip, forKey: "relayip")
        }
    }
    //釣り銭機のポート
    @Published var relayport: String{
        didSet{
            //プロパティ設定領域への保存
            UserDefaults.standard.set(relayport, forKey: "relayport")
        }
    }
    //釣り銭機のアドレス
    @Published var changerip: String{
        didSet{
            //プロパティ設定領域への保存
            UserDefaults.standard.set(changerip, forKey: "changerip")
        }
    }
    //釣り銭機のポート
    @Published var changerport: String{
        didSet{
            //プロパティ設定領域への保存
            UserDefaults.standard.set(changerport, forKey: "changerport")
        }
    }
    //釣り銭なし完了時の案内文
    @Published var confermmsgzero: String{
        didSet{
            //プロパティ設定領域への保存
            UserDefaults.standard.set(confermmsgzero, forKey: "confermmsgzero")
        }
    }
    //釣り銭あり完了時の案内文
    @Published var confermmsg: String{
        didSet{
            //プロパティ設定領域への保存
            UserDefaults.standard.set(confermmsg, forKey: "confermmsg")
        }
    }
    //<Add 20220425 V1.30>
    //ログ書き出しのオンオフ
    @Published var loguse: Bool{
        didSet{
            //プロパティ設定領域への保存
            UserDefaults.standard.set(loguse, forKey: "loguse")
        }
    }
    //</Add 20220425 V1.30>
    //初期化処理
    init() {
        //プロパティ設定領域からの呼び出し
        relayip = UserDefaults.standard.string(forKey: "relayip") ?? "localhost"
        relayport = UserDefaults.standard.string(forKey: "relayport") ?? ""
        changerip = UserDefaults.standard.string(forKey: "changerip") ?? ""
        changerport = UserDefaults.standard.string(forKey: "changerport") ?? ""
        confermmsgzero = UserDefaults.standard.string(forKey: "confermmsgzero") ?? ""
        confermmsg = UserDefaults.standard.string(forKey: "confermmsg") ?? ""
        loguse = UserDefaults.standard.bool(forKey: "loguse") //<Add 20220425 V1.30 />
    }

}
