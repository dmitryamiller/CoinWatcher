//
//  ScanQRViewController.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 8/22/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import UIKit
import AVFoundation

protocol ScanQRViewControllerDelegate : class {
    func scanner(_: ScanQRViewController, didScanCode: URL)
    func scanner(_: ScanQRViewController, isValid: URL?) -> Bool
}

class ScanQRViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    @IBOutlet weak var previewContainer: UIView?
    
    weak var delegate: ScanQRViewControllerDelegate?
    
    private var session: AVCaptureSession?
    private var previewLayer:AVCaptureVideoPreviewLayer?
    private var input:AVCaptureDeviceInput?
    
    private let supportedBarCodes = [AVMetadataObjectTypeQRCode, AVMetadataObjectTypeDataMatrixCode]
    
    private var containerView: UIView {
        if let v = self.previewContainer {
            return v
        } else {
            return self.view
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        
        self.input = input
        self.session = AVCaptureSession()
        self.session?.addInput(input)
        
        let metadataOutput = AVCaptureMetadataOutput()
        self.session?.addOutput(metadataOutput)
        
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = self.supportedBarCodes
        
        
        guard let previewLayer = AVCaptureVideoPreviewLayer(session: self.session) else { return }
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        previewLayer.connection.videoOrientation = .portrait
        self.previewLayer = previewLayer
        
        self.containerView.layer.addSublayer(previewLayer)
        self.start()        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.previewLayer?.frame = self.containerView.bounds
    }
    
    // MARK: - AVCaptureMetadataOutputObjectsDelegate
    
    public func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {        
        if metadataObjects == nil || metadataObjects.count == 0 {
            return
        }
        
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        guard let codeURL = URL(string:metadataObj.stringValue)?.standardized else { return }
        
        if self.delegate?.scanner(self, isValid: codeURL) ?? false {
            self.vibrate()
            self.delegate?.scanner(self, didScanCode: codeURL)
        }
    }

    
    // MARK: Misc - functions
    func start() {
        self.session?.startRunning()
    }
    
    func stop() {
        self.session?.stopRunning()
    }
    
    private func vibrate() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }

}
