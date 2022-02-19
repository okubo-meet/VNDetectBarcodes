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
    //バーコードの位置に表示する枠線
    var barcodeBox = CAShapeLayer()
    // セッションのインスタンス
    private let captureSession = AVCaptureSession()
    //カメラ映像のプレビューレイヤー
    let previewLayer = AVCaptureVideoPreviewLayer()
    //ビデオデータ出力のインスタンス
    let videoDataOutput = AVCaptureVideoDataOutput()
    //メタデータ出力のインスタンス
    let metaDataOutput = AVCaptureMetadataOutput()
    
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
            // フレームからImageBufferに変換
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            //バーコード検出用のハンドラ
            let requestHandler = VNSequenceRequestHandler()
            //Vision 画像内のバーコードを検出するリクエスト
            let barcordesRequest = VNDetectBarcodesRequest { result, _ in
                DispatchQueue.main.async {
                    
                    guard let barcode = result.results?.first as? VNBarcodeObservation else {
                        self.parent.clearBox()
                        return
                    }
                    //枠線表示
                    self.parent.showBox(barcode: barcode)
                    //読み取ったコードを出力
                    if let value = barcode.payloadStringValue {
                        if value != self.parent.cameraViewModel.barcodeData {
                            print("読み取り：\(value)")
                            self.parent.cameraViewModel.barcodeData = value
                            self.parent.cameraViewModel.barcodeType = barcode.symbology.rawValue
                            //アラート表示
//                            self.parent.showAlert()
                        }
                    }
                }
            }// VNDetectBarcodesRequest
            
            //バーコード検出開始、orientationで座標の反転に対応
            try? requestHandler.perform([barcordesRequest], on: pixelBuffer, orientation: .downMirrored)
        }// captureOutput
        
    }// Coordinator
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    
    //画面起動時の関数
    func makeUIViewController(context: UIViewControllerRepresentableContext<CameraView>) -> UIViewController {
        //Viewのサイズ
        viewController.view.frame = UIScreen.main.bounds
        //カメラの映像をセット
        setPreviewLayer()
        setCamera()
        //出力(映像)
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8PlanarFullRange)]
        //AVCaptureVideoDataOutputSampleBufferDelegateを呼び出す設定
        videoDataOutput.setSampleBufferDelegate(context.coordinator, queue: DispatchQueue(label: "camera_frame_processing_queue"))
        //出力(メタデータ)
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
    //カメラのキャプチャ映像をViewにセットする関数
    func setPreviewLayer() {
        //プレビューするキャプチャを設定
        previewLayer.session = captureSession
        //プレビューの画面サイズ
        previewLayer.frame = viewController.view.bounds
        //プレビューをViewに追加
        viewController.view.layer.addSublayer(previewLayer)
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
    //バーコードの位置に線を表示する
    func showBox(barcode: VNBarcodeObservation) {
        let boxOnScreen = previewLayer.layerRectConverted(fromMetadataOutputRect: barcode.boundingBox)
        let boxPath = CGPath(rect: boxOnScreen, transform: nil)
        barcodeBox.path = boxPath
        barcodeBox.borderWidth = 3
        barcodeBox.fillColor = Color(.clear).cgColor
        barcodeBox.strokeColor = Color(.red).cgColor
        //枠線表示
        previewLayer.addSublayer(barcodeBox)
    }
    //枠線を削除する関数
    func clearBox() {
        barcodeBox.removeFromSuperlayer()
    }
    //画面更新時の関数
    func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<CameraView>) {
        
    }
}

