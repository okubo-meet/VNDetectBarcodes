//
//  CameraViewModel.swift
//  CameraApp
//
//  Created by 大久保徹郎 on 2022/01/29.
//

import UIKit
import SwiftUI

class CameraViewModel: ObservableObject {
    //バーコードの値
    @Published var barcodeData = ""
    //バーコードの種類
    @Published var barcodeType = ""
}
