//
//  CameraView.swift
//  CameraApp
//
//  Created by 大久保徹郎 on 2022/01/29.
//

import SwiftUI
import AVFoundation
import Vision

struct CameraView: UIViewControllerRepresentable {
    @EnvironmentObject var cameraViewModel: CameraViewModel
    //環境変数で取得したdismissハンドラー
    @Environment(\.dismiss) var dismiss
    //UIViewControllerのインスタンス生成
    let viewController = UIViewController()
    // セッションのインスタンス
    private let captureSession = AVCaptureSession()
    
    class Coordinator: AVCaptureSession, AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
        let parent: CameraView
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        //メタデータを検出した時のデリゲートメソッド
        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            print("メタデータ：\(metadataObjects)")
        }
        //新たなビデオフレームが書き込むたびに呼び出されるデリゲートメソッド
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            //バーコード検出用のハンドラ
            let requestHandler = VNSequenceRequestHandler()
            //Vision 画像内のバーコードを検出するリクエスト
            let barcordesRequest = VNDetectBarcodesRequest { result, _ in
                guard let barcode = result.results?.first as? VNBarcodeObservation else {
                    return
                }
                
                //読み取ったコードを出力
                if let value = barcode.payloadStringValue {
                    if value != self.parent.cameraViewModel.barcodeData {
                        print("読み取り：\(value)")
                        self.parent.cameraViewModel.barcodeData = value
                        self.parent.cameraViewModel.barcodeType = barcode.symbology.rawValue
                        //アラート表示
                        self.parent.showAlert()
                    }
                }
            }
            
            //バーコード検出開始
            try? requestHandler.perform([barcordesRequest], on: pixelBuffer)
            
        }
        
        
    }// Coordinator
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    
    //画面起動時の関数
    func makeUIViewController(context: UIViewControllerRepresentableContext<CameraView>) -> UIViewController {
        //Viewのサイズ
        viewController.view.frame = UIScreen.main.bounds
        //枠線
        let boxBprder = CALayer()
        boxBprder.frame = CGRect(x: 45, y: 200, width: 300, height: 100)
        boxBprder.borderColor = UIColor.red.cgColor
        boxBprder.borderWidth = 2
        //カメラ映像のプレビュー
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        //プレビューの画面サイズ
        previewLayer.frame = viewController.view.bounds
        //プレビューをViewに追加
        viewController.view.layer.addSublayer(previewLayer)
        previewLayer.addSublayer(boxBprder)
        //カメラの映像をセット
        setCamera()
        //出力(映像)
        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8PlanarFullRange)]
        //AVCaptureVideoDataOutputSampleBufferDelegateを呼び出す設定
        videoDataOutput.setSampleBufferDelegate(context.coordinator, queue: .main)
        //出力(メタデータ)
        let metaDataOutput = AVCaptureMetadataOutput()
        //検出するメタデータのタイプ
        metaDataOutput.metadataObjectTypes = metaDataOutput.availableMetadataObjectTypes
        //AVCaptureMetadataOutputObjectsDelegateを呼び出す設定
        metaDataOutput.setMetadataObjectsDelegate(context.coordinator, queue: .main)
        //映像からメタデータを出力できるよう設定
        captureSession.addOutput(videoDataOutput)
        
        return viewController
    }// makeUIViewController
    
    //カメラをセットする関数
    func setCamera() {
        //使用するカメラと撮っている映像を設定
        guard let captureDevice = AVCaptureDevice.default(for: .video),
              let deviceInput = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        //撮影している情報をセッションに渡す
        captureSession.addInput(deviceInput)
        //キャプチャセッション開始
        captureSession.startRunning()
    }
    //バーコード読み取り成功のアラートを出す関数
    func showAlert() {
        print("アラート")
        captureSession.stopRunning()
        let alert = UIAlertController(title: "読み取り成功", message: cameraViewModel.barcodeData, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: { _ in
            dismiss()
        })
        alert.addAction(action)
        viewController.present(alert, animated: true, completion: nil)
    }
    //画面更新時の関数
    func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<CameraView>) {
        
    }
}

