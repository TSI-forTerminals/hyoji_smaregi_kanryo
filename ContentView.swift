//
//  ContentView.swift
//  smaregi_kanryo_hyoji
//
//  Created by 城川一理 on 2021/08/08.
//

import SwiftUI

import AudioToolbox

//遷移先の画面で遷移元の画面の関数を呼ぶ仕組み①
protocol  MyProtocol {
    func ServerClose()
}

struct ContentView: View, MyProtocol {
    @EnvironmentObject var dispitems: DispItems
    //<Add 20210922 V1.8?>
    @State private var showingAlert = false
    //</Add 20210922 V1.8?>
    
    public static var vtitle: String = "お会計"
    @State var blnStart: Bool = false
    let app = Server(host: UserDefaults.standard.string(forKey: "relayip") ?? "",port: UserDefaults.standard.string(forKey: "relayport") ?? "8888")
    //let app = Server(host: UserDefaults.standard.string(forKey: "relayip") ?? "",port: UserDefaults.standard.integer(forKey: "relayport"))
    var body: some View {
        
        NavigationView{
            //背景色の設定 スマレジ背景色規定 #0087e6
            ZStack {
                /*Color(red: 0, green: 0.95, blue: 0, opacity: 0.2)
                 .edgesIgnoringSafeArea(.all)*/
                Color(red: 0, green: 0.53, blue: 0.96, opacity: 1)
                    .edgesIgnoringSafeArea(.all)
                VStack{
                    VStack{
                        /*Button( action: {
                         ServerStart()
                         blnStart = true
                         }  ){
                         Text("受信開始")
                         .font(.title)
                         .padding()
                         }
                         .disabled(blnStart) */
                        
                        Text(dispitems.customercode)
                            .font(.largeTitle)
                            .foregroundColor(Color.white)
                            .padding()
                        Text(dispitems .customername + " 様")
                            .font(.largeTitle)
                            .foregroundColor(Color.white)
                            .padding()
                        
                        //Spacer()
                    }
                    //0903 Spacer()
                    VStack(){ //直下の要素数は１０個まで
                        Group{
                            /*Text(ContentView.vtitle)
                             .font(.largeTitle)
                             .foregroundColor(Color.white)
                             .padding() */
                            Text("ご請求 " + getComma(num:  dispitems.billingamount))
                                .font(.system(size: 50, weight: .black, design: .default))
                                .foregroundColor(Color.white)
                                .padding()
                                .frame(width: 600.0)
                            Text("投入金額　" + getComma(num: dispitems.depositamount))
                                .font(.largeTitle)
                                .foregroundColor(Color.white)
                                .padding()
                                .frame(width: 500.0)
                            //<Add 20210831>
                            if (dispitems.confirmstatus == "2"){
                                PopupView()
                            }
                            //</Add 20210831>
                            Text("不足金額　" + getComma(num: dispitems.minusamount))
                                .font(.largeTitle)
                                .foregroundColor(Color.white)
                                .padding()
                                .frame(width: 500.0)
                            Divider()
                                .frame(width: 600.0, height: 2)
                                .background(Color.white)
                            Text("おつり　" + getComma(num: dispitems.chargeamount))
                                .font(.system(size: 50, weight: .black, design: .default))
                                .foregroundColor(Color.white)
                                .padding()
                                .frame(width: 600.0)
                        }
                    }
                    //Spacer()
                    //案内表示
                    Text(dispitems.announce)
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.yellow)
                        .padding()
                    
                    ZStack{
                        //Spacer()
                        HStack(spacing:20){
                            Text("")//隙間開け用
                            Button( action:
                                        {
                                //20210826
                                if (dispitems.billingamount != "0") {
                                    dispitems.confirmstatus = "3"
                                    dispitems.announce = "キャンセル処理中です。しばらくお待ち下さい。"
                                }
                            })
                            {
                                Text("キャンセル")
                                //.font(.title)
                                    .font(.body)
                                    .foregroundColor(Color.red)
                                    .frame(width: 120.0, height: 50.0)
                                    .background(Color.white)
                            }
                            .disabled(dispitems.confirmstatus == "3")
                            //Text("") //間隔あけ
                            Spacer()
                        }
                        Button( action:
                                    {dispitems.confirmstatus = "2"
                            if (dispitems.chargeamount == "0"){
                                dispitems.announce = UserDefaults.standard.string(forKey: "confermmsgzero") ?? ""
                            }else{
                                dispitems.announce = UserDefaults.standard.string(forKey: "confermmsg") ?? ""
                            }
                            //<Add 20210930 V1.9>
                            //<Del 20211112 操作側が完了するまでリセットしない V1.16>
                            //                        let que = DispatchQueue.global()
                            //                        que.async {
                            //                            Thread.sleep(forTimeInterval: 5)
                            //                            //表示画面をクリアする
                            //                            dispitems.announce = ""
                            //                            dispitems.confirmstatus = "0"
                            //                            dispitems.customercode = ""
                            //                            dispitems.customername = ""
                            //                            dispitems.billingamount = "0"
                            //                            dispitems.depositamount = "0"
                            //                            dispitems.minusamount = "0"
                            //                            dispitems.chargeamount = "0"
                            //                            dispitems.jusinOK = "受信OK"
                            //                        }
                            //</Del 20211112 操作側が完了するまでリセットしない V1.16>
                            //</Add 20210930 V1.9>
                        })
                        {
                            Text("精　　算")
                                .font(Font.system(size: 48).bold())
                                .frame(width: 550.0, height: 65.0)
                                .background(Color.white)
                        }
                        .disabled(dispitems.confirmstatus != "1")
                        //Spacer()
                        //Spacer()
                        //Spacer()
                    }
                    Spacer()
                    Spacer() //0903
                }
                .navigationBarTitle("精算", displayMode: .inline)
                .navigationBarItems(leading: HStack {
                    Button(action: {
                        ServerStart()
                        blnStart = true
                    }  ){
                        Text("　") //20210927「受信開始」を削除
                        //.foregroundColor(Color.black)
                    }.disabled(blnStart)
                    //<Add 20210927 V1.8?>
                    Text(dispitems.jusinOK)
                        .foregroundColor(Color.green)
                    //</Add 20210927 V1.8?>
                }, trailing: NavigationLink(
                    destination: SettingView(delegate: self)){
                        Text("設定")
                            .foregroundColor(Color.black)
                    })
                //遷移先の画面で遷移元の画面の関数を呼ぶ仕組み②　SettingView(delegate: self)の部分
                
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification), perform: { _ in
            //<Upd 20211013 V1.9>
            //ServerClose()
            ServerClosenow()
            //</Upd 20211013 V1.9>
            //willResignActiveNotification o サンプルから
            //didEnterBackgroundNotification o
            //willTerminateNotification x
        })
        .navigationViewStyle(StackNavigationViewStyle())// iPhoneとiPadの見え方を同じにする
        
        //<Add 202109 V1.8?>
        .alert(isPresented: $showingAlert) {
            //<Upd 20211020 V1.10>
            //            Alert(title: Text("受信開始"),
            //                  message: Text("受信を開始します。"),
            //                  primaryButton: .cancel(Text("OK"),
            //                                          action: {
            //                ServerStart()
            //                blnStart = true
            //            }), secondaryButton: .default(Text("キャンセル"))) // ボタンがタップされた時の処理
            Alert(title: Text("受信開始"),
                  message: Text("受信を開始します。"),
                  dismissButton: .default(Text("OK"),
                                          action: {
                ServerStart()
                blnStart = true
            }))
            //</Upd 20211020 V1.10>
        }
        
        .onAppear(perform: {
            showingAlert = true
        })
        //</Add 202109 V1.7?>
    }
    
    func ServerStart(){
        let queue = DispatchQueue.global(qos: .userInteractive)
        queue.async {
            //<Upd 20211013 V1.9>
            //app.start(contentview: self)
            app.start(hostp:UserDefaults.standard.string(forKey: "relayip") ?? "",portp:UserDefaults.standard.string(forKey: "relayport") ?? "8888", contentview: self)
            //</Upd 20211013 V1.9>
        }
    }
    
    func ServerClose(){
        app.stop()
        
        Thread.sleep(forTimeInterval: 0.5)
        exit(0)
    }
    
    //<Add 20211013 V1.9>
    func ServerClosenow(){
        app.stop()
        exit(0)
    }
    //</Add 20211013 V1.9>
    
    func getComma(num: String) -> String {
        let intnum = Int(num) ?? 0
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        let number = "\(formatter.string(from: NSNumber(value: intnum)) ?? "")円"
        
        return number
    }
    
}

struct PopupView: View {
    @EnvironmentObject var dispitems: DispItems
    //@Binding var isPresent: Bool
    var body: some View {
        VStack(spacing: 12) {
            //Spacer()
            VStack(){
                Text("")
                Button(action:
                        {
                    withAnimation {
                        //isPresent = false
                        dispitems.confirmstatus = "0"
                    }
                }, label: {
                    Text("精算が完了しました")
                        .font(Font.system(size: 36).bold())
                        .foregroundColor(Color.green)
                })
                //Spacer()
                Text("")
                if (dispitems.chargeamount == "0"){
                    //48ポで１３文字
                    //精算が終りました。
                    //気を付けてお帰り下さい。
                    Text(dispitems.confermmsgzero)
                        .font(Font.system(size: 48).bold())
                        .lineLimit(nil)
                        .padding()
                }else{
                    //おつりをお受け取りの上
                    //気を付けてお帰り下さい。
                    Text(dispitems.confermmsg)
                        .font(Font.system(size: 48).bold())
                        .lineLimit(nil)
                        .padding()
                }
            }
            .background(Color.white)
            .cornerRadius(12)
            //Spacer()
            //Spacer()
            //Spacer()
        }
        .frame(width: 600, height: 685, alignment: .center)
        .padding()
        .background(Color(red: 0, green: 0.53, blue: 0.96, opacity: 1))
        .onAppear(perform: {
            //https://iphonedev.wiki/index.php/AudioServices
            let soundIdRing: SystemSoundID = 1007
            AudioServicesPlaySystemSound(soundIdRing)
        })
    }
}

struct SettingView: View {
    @EnvironmentObject var dispitems: DispItems
    
    //遷移先の画面で遷移元の画面の関数を呼ぶ仕組み③
    var delegate:MyProtocol
    
    var body: some View {
        Group{
            //Spacer()
            Text("釣銭機の状態　" + dispitems.chargerstatus)
                .padding()
            HStack{
                Text("サーバー（この端末）のipアドレス")
                    .padding()
                TextField("ipアドレス", text: $dispitems.relayip)
                    .padding()
                    .frame(width: 200.0)
            }
            HStack{
                Text("サーバー受信ポート番号")
                    .padding()
                TextField("ポート番号", text: $dispitems.relayport)
                    .padding()
                    .frame(width: 200.0)
            }
            HStack{
                Text("釣り銭機のipアドレス")
                    .padding()
                TextField("釣り銭機のipアドレス", text: $dispitems.changerip)
                    .padding()
                    .frame(width: 200.0)
            }
            HStack{
                Text("釣り銭機のポート番号")
                    .padding()
                TextField("釣り銭機のポート番号", text: $dispitems.changerport)
                    .padding()
                    .frame(width: 200.0)
            }
        }
        Group{
            HStack{
                Text("精算ボタン押下時の文言（おつり有り）")
                    .padding()
                TextField("例：おつりと請求書兼領収書をお受け取り下さい。", text: $dispitems.confermmsg)
                    .padding()
                    .frame(width: 400.0)
            }
            HStack{
                Text("精算ボタン押下時の文言（おつり無し）")
                    .padding()
                TextField("例：請求書兼領収書をお受け取り下さい。", text: $dispitems.confermmsgzero)
                    .padding()
                    .frame(width: 400.0)
            }
            //<Add 20220425 V1.30>
            Toggle(isOn: $dispitems.loguse){
                Text("ログを記録する：" + (dispitems.loguse ? "On": "Off"))
            }
            .frame(width: 400.0)
            //</Add 20220425 V1.30>
            //遷移先の画面で遷移元の画面の関数を呼ぶ仕組み④
            Button(action: self.delegate.ServerClose)
            {
                Text("このアプリを終了")
                    .font(.largeTitle)
            }
            Text("")
            Button(action:{
                enqRtn = ResetdispRtn(host: dispitems.relayip, port: dispitems.relayport)
                showAlert = true
                
            },label: { Text("導通")
                .font(.title)}).alert(isPresented: $showAlert, content: {
                    Alert(title: Text("直ぐにこの表示が出る場合は、導通できていません。"), message: Text(enqRtn))
                })
            Text("Version 1.33")//20220104
        }
    }
    @State private var showAlert = false
    @State private var enqRtn = ""
    
}

//釣り銭機通信ステータス要求（同期）
func ResetdispRtn(host:String, port:String)->String{
    var rtn: String = ""
    let hostadder = host + ":" + port
    let chngrreq = "http://" + hostadder + "/resetdisp"
    
    let semaphore = DispatchSemaphore(value: 0)
    
    ResponseGetNosync(urlstring: chngrreq,completion: {result in
        if let result = result {
            rtn = result
            //結果を出力
            print(result)
            // ここに書くとhungupする semaphore.signal()
        } else {
            print("通信エラー")
        }
        semaphore.signal() //ここならハングしない
    })
    semaphore.wait()
    return rtn
}
//httpリクエスト共通関数(同期制御用)
func ResponseGetNosync(urlstring:String, completion: @escaping
(String?)->Void){
    
    guard let url = URL(string: urlstring) else { return }
    
    var req = URLRequest(url: url) //可能な限り`NSMutableURLRequest`ではなく`URLRequest`を使う
    req.httpMethod = "GET"
    //req.timeoutInterval = 2
    //無効の様
    //req.setValue("close", forHTTPHeaderField: "Connection")
    //if let headers = req.allHTTPHeaderFields{
    //     print("\(headers)")
    //}
    
    //waitingなんてフラグは使用しない
    let task = URLSession.shared.dataTask(with: req as URLRequest , completionHandler: { data, res, err  in
        //非nilの値を後で利用するならif-letを使用した方が良い
        if let data = data, err == nil {
            //print(data as NSData, res!.textEncodingName ?? "encoding unknown") //デバッグ用
            
            let text: String? = String(data: data, encoding: .utf8) //可能な限り`NSString`ではなく`String`を利用する
            var result: String
            result = text!
            //完了ハンドラーの中で自前に完了ハンドラーを呼び出す
            completion(result)
        } else {
            //エラーを黙って無視しない
            if let error = err {
                print("釣銭機通信エラー")
                print(error)
            }
            if data == nil {
                print("data is nil")
            }
            //何も書かれていなかったが、エラー時にはnilを完了ハンドラーに渡すことにする
            completion(nil)
        }
    })
    task.resume()
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(DispItems())
    }
}
