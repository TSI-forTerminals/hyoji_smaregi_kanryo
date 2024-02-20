//
//  hyoji_smaregi_kanryoApp.swift
//  hyoji_smaregi_kanryo
//
//  Created by tkartesv01macpc on 2021/09/25.
//

import SwiftUI

@main
struct hyoji_smaregi_kanryoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(DispItems())
        }
    }
}
