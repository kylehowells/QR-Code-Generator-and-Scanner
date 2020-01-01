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

	// MARK: View Life Cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		view.backgroundColor = UIColor.black
		
		// Setup Camera Capture
		captureSession = AVCaptureSession()

		// Get which camera we will use (there are normally between 2 to 4 camera 'devices' on iPhones
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }

		// Now the camera is setup add a metadata output
        let metadataOutput = AVCaptureMetadataOutput()

        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr] // Also have things like Face, body, cats
        } else {
            failed()
            return
        }

		// Setup the UI to show the camera
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        cameraContainerView.layer.addSublayer(previewLayer)

        captureSession.startRunning()
	}
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		previewLayer?.frame = cameraContainerView.layer.bounds
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

        if (captureSession?.isRunning == false) {
            captureSession?.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if (captureSession?.isRunning == true) {
            captureSession?.stopRunning()
        }
    }
	
	@IBAction func startStopPressed(_ sender: Any) {
		if (captureSession?.isRunning == true) {
            captureSession?.stopRunning()
			cameraContainerHeightConstraint.priority = UILayoutPriority(500)
        }
		else {
            captureSession?.startRunning()
			cameraContainerHeightConstraint.priority = UILayoutPriority(1000)
		}
		
		UIView.animate(withDuration: 0.2, animations: {
			self.view.layoutIfNeeded()
		})
	}
	
	
	
	func failed() {
        let ac = UIAlertController(title: "Scanning failed", message: nil, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Dismiss", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }
	
	
	// MARK: AVCaptureMetadataOutputObjectsDelegate
	
	func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
			
            if stringValue != outputTextView.text {
                print("QR Code: \(stringValue)")
                outputTextView.text = stringValue
            }
        }
    }
}

