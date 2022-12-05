//
//  SecondViewController.swift
//  QR Codes
//
//  Created by Kyle Howells on 31/12/2019.
//  Copyright © 2019 Kyle Howells. All rights reserved.
//

import UIKit
import AVFoundation

class ReaderViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
	
	@IBOutlet weak var cameraContainerView: UIView!
	@IBOutlet weak var cameraContainerHeightConstraint: NSLayoutConstraint!
	
	@IBOutlet weak var startStopButton: UIButton!
	@IBOutlet weak var outputTextView: UITextView!
	
	var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    var qrCodeBounds:UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        view.layer.borderColor = UIColor.green.cgColor
        view.layer.borderWidth = 3
        return view
    }()
	
	
	// MARK: View Life Cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.view.backgroundColor = UIColor.black
		
		// Setup Camera Capture
		let captureSession = AVCaptureSession()
		self.captureSession = captureSession
		
		// Get the default camera (there are normally between 2 to 4 camera 'devices' on iPhones)
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
		
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

		if (self.captureSession.canAddInput(videoInput)) {
			self.captureSession.addInput(videoInput)
        } else {
			self.failed() // Simulator mostly
            return
        }

		// Now the camera is setup add a metadata output
        let metadataOutput = AVCaptureMetadataOutput()
		
		if (self.captureSession.canAddOutput(metadataOutput)) {
			self.captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr] // Also have things like Face, body, cats
        } else {
			self.failed()
            return
        }
		
		// Setup the UI to show the camera
		self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
		self.previewLayer.frame = self.view.layer.bounds
		self.previewLayer.videoGravity = .resizeAspectFill
		self.cameraContainerView.layer.addSublayer(self.previewLayer)
		
		self.qrCodeBounds.alpha = 0
		self.cameraContainerView.addSubview(self.qrCodeBounds)
		
		DispatchQueue.global(qos: .background).async(execute: {
			captureSession.startRunning()
		})
	}
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		self.previewLayer?.frame = self.cameraContainerView.layer.bounds
		
		// Fix orientation
		if let connection = self.previewLayer?.connection {
			let orientation = self.view.window?.windowScene?.interfaceOrientation ?? UIInterfaceOrientation.portrait
			let previewLayerConnection : AVCaptureConnection = connection

			if (previewLayerConnection.isVideoOrientationSupported) {
				switch (orientation) {
					case .landscapeRight:
						previewLayerConnection.videoOrientation = AVCaptureVideoOrientation.landscapeRight
					case .landscapeLeft:
						previewLayerConnection.videoOrientation = AVCaptureVideoOrientation.landscapeLeft
					case .portraitUpsideDown:
						previewLayerConnection.videoOrientation = AVCaptureVideoOrientation.portraitUpsideDown
					default:
						previewLayerConnection.videoOrientation = AVCaptureVideoOrientation.portrait
				}
			}
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

		if (self.captureSession?.isRunning == false) {
			self.captureSession?.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

		if (self.captureSession?.isRunning == true) {
			self.captureSession?.stopRunning()
        }
    }
	
	@IBAction func startStopPressed(_ sender: Any)
	{
		if (self.captureSession?.isRunning == true) {
			self.captureSession?.stopRunning()
			self.cameraContainerHeightConstraint.priority = UILayoutPriority(500)
        }
		else {
			self.captureSession?.startRunning()
			self.cameraContainerHeightConstraint.priority = UILayoutPriority(1000)
		}
		
		UIView.animate(withDuration: 0.2, animations: {
			self.view.layoutIfNeeded()
		})
	}
	
	
	
	func failed() {
        let ac = UIAlertController(title: "Scanning failed", message: nil, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Dismiss", style: .default))
		self.present(ac, animated: true)
		
		self.captureSession = nil
    }
    
    
    func showQRCodeBounds(frame: CGRect?) {
        guard let frame = frame else { return }
        
		self.qrCodeBounds.layer.removeAllAnimations() // resets any previous animations and cancels the fade out
		self.qrCodeBounds.alpha = 1
		self.qrCodeBounds.frame = frame
		
        UIView.animate(withDuration: 0.2, delay: 1, options: [], animations: { // after 1 second fade away
            self.qrCodeBounds.alpha = 0
        })
    }
	
	
	// MARK: AVCaptureMetadataOutputObjectsDelegate
	
	func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            // Get text value
            if stringValue != outputTextView.text {
                print("QR Code: \(stringValue)")
				self.outputTextView.text = stringValue
            }
            
            // Show bounds
			let qrCodeObject: AVMetadataObject? = self.previewLayer.transformedMetadataObject(for: readableObject)
			self.showQRCodeBounds(frame: qrCodeObject?.bounds)
        }
    }
	
	
	
	// MARK: - Detect QR Code From Static Image
	// https://stackoverflow.com/a/49275021/458205
	
	/// Detect a QR Code in a static image
	/// - Parameter image: The image to scan for QR codes
	/// - Returns: The found QR code details
	func detectQRCode(_ image: UIImage?) -> [CIFeature]?
	{
		if let image = image, let ciImage = CIImage.init(image: image)
		{
			var options: [String: Any]
			
			let context = CIContext()
			options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
			
			let qrDetector = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: options)
			
			if ciImage.properties.keys.contains((kCGImagePropertyOrientation as String))
			{
				options = [CIDetectorImageOrientation: ciImage.properties[(kCGImagePropertyOrientation as String)] ?? 1]
			}
			else {
				options = [CIDetectorImageOrientation: 1]
			}
			
			let features = qrDetector?.features(in: ciImage, options: options)
			return features
		}
		
		return nil
	}
	
	/*
	 Usage:
	 let exampleImage: UIImage = ....
	 
	 if let features = detectQRCode(exampleImage), !features.isEmpty {
		 for case let row as CIQRCodeFeature in features {
			 print(row.messageString ?? "Contents failed to decode")
		 }
	 }
	 */
}
