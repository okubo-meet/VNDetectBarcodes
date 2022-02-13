//
//  ContentView.swift
//  CameraApp
//
//  Created by 大久保徹郎 on 2022/01/28.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var cameraViewModel: CameraViewModel
    @State var isShowCamera = false
    var body: some View {
        VStack {
            Button(action: {
                isShowCamera = true
            }) {
                Text("カメラ起動")
            }
            VStack {
                Text(cameraViewModel.barcodeType)
                Text(cameraViewModel.barcodeData)
            }
        }
        .sheet(isPresented: $isShowCamera) {
            CameraView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
