//
//  CameraAppApp.swift
//  CameraApp
//
//  Created by 大久保徹郎 on 2022/01/28.
//

import SwiftUI

@main
struct CameraAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(CameraViewModel())
        }
    }
}
