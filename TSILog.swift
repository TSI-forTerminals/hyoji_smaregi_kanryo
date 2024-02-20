//
//  TSILog.swift
//  smaregi_kanryo_hyoji
//
//  Created by 城川一理 on 2022/04/21.
//

import Foundation

class TSILog {
    private static let file = "log.csv"

    static func write(_ log: String, loguse: Bool) {
        if !loguse { //書き出しをしない
            return
        }
        writeToFile(text: log)
    }
    static func write(_ log: String, funcnm: String, line: Int, loguse: Bool) {
        if !loguse { //書き出しをしない
            return
        }

        let dt = Date()
        let dateFormatter = DateFormatter()
        /// カレンダー、ロケール、タイムゾーンの設定（未指定時は端末の設定が採用される）
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.timeZone = TimeZone(identifier:  "Asia/Tokyo")
         
        /// 変換フォーマット定義（未設定の場合は自動フォーマットが採用される）
        //dateFormatter.dateFormat = "yyyy年M月d日(EEEEE) H時m分s秒"
         
        /// 自動フォーマットのスタイル指定
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
         
        /// データ変換（Date→テキスト）
        let dateString = dateFormatter.string(from: dt)
        let dec = dateString + " line:" + line.description + " func:" + funcnm + " " + log + "\n"
        writeToFile(text: dec)
    }

    private static func writeToFile(text: String) {
        guard let documentPath =
            FileManager.default.urls(for: .documentDirectory,
                                     in: .userDomainMask).first else { return }

        let dt = Date()
        let calendar = Calendar(identifier: .gregorian)
        let tody = calendar.component(.day, from: dt)
        let file = "log" + tody.description + ".csv"
        
        //前月の同日の翌日ログファイルを削除する
        let modifiedDate = Calendar.current.date(byAdding: .day, value: 1, to: dt)!
        let tomorrow = calendar.component(.day, from: modifiedDate)
        let delfile = "log" + tomorrow.description + ".csv"
        let delpath = documentPath.appendingPathComponent(delfile)
        if (fileExists(atPath: delpath.path)) {
            removeItem(atPath: delpath.path)
        }
        
        let path = documentPath.appendingPathComponent(file)
        _ = appendText(fileURL: path, text: text)
    }

    private static func appendText(fileURL: URL, text: String) -> Bool {
        guard let stream = OutputStream(url: fileURL, append: true) else { return false }
        stream.open()

        defer { stream.close() }

        guard let data = text.data(using: .utf8) else { return false }

        let result = data.withUnsafeBytes({ (rawBufferPointer: UnsafeRawBufferPointer) -> Int in
            let bufferPointer = rawBufferPointer.bindMemory(to: UInt8.self)
            return stream.write(bufferPointer.baseAddress!, maxLength: data.count)
        })
//元のロジック
//        let result = data.withUnsafeBytes {
//            stream.write($0, maxLength: data.count)
//        }
//元のロジック
        return (result > 0)

//        let result: () = data.withUnsafeBytes{ rawPtr in
//            guard let ptr = rawPtr.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return }
//            stream.write(ptr.advanced(by: 0), maxLength: data.count)
//        }
//        return true
    }
    /// ファイルがあるか確認する
    /// - Parameter path: 対象ファイルパス
    /// - Returns: ファイルがあるかどうか
    private static func fileExists(atPath path: String) -> Bool {
        return FileManager.default.fileExists(atPath: path)
    }
    
    /// ファイルを削除する
    /// - Parameter path: 対象ファイルパス
    private static func removeItem(atPath path: String) {
        do {
           try FileManager.default.removeItem(atPath: path)
        } catch let error {
            print(error.localizedDescription)
        }
    }

    //前月の同日の翌日ログファイルを削除する
    static func removeTomorrowFile(noDummy: Bool) {
        if !noDummy { //書き出しをしない
            return
        }

        guard let documentPath =
            FileManager.default.urls(for: .documentDirectory,
                                     in: .userDomainMask).first else { return }

        let dt = Date()
        let calendar = Calendar(identifier: .gregorian)
        
        let modifiedDate = Calendar.current.date(byAdding: .day, value: 1, to: dt)!
        let tomorrow = calendar.component(.day, from: modifiedDate)
        let delfile = "log" + tomorrow.description + ".csv"
        let delpath = documentPath.appendingPathComponent(delfile)
        
        if (fileExists(atPath: delpath.path)) {
            removeItem(atPath: delpath.path)
        }
    }

}
