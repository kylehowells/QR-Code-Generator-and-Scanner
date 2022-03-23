//
//  CustomDesignViewController.swift
//  QR Codes
//
//  Created by Kyle Howells on 23/03/2022.
//  Copyright © 2022 Kyle Howells. All rights reserved.
//

import UIKit

class CustomDesignViewController: UIViewController {

	@IBOutlet weak var normalImageView: UIImageView!
	@IBOutlet weak var customImageView: UIImageView!
	
	@IBOutlet weak var exampleLabel: UILabel!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		self.view.backgroundColor = UIColor(red: 245.0/255.0, green: 246.0/255.0, blue: 249.0/255.0, alpha: 1.0)
		
		self.normalImageView.layer.magnificationFilter = .nearest
		
		self.normalImageView.layer.borderColor = UIColor(white: 0.9, alpha: 1).cgColor
		self.normalImageView.layer.borderWidth = 1
		
		self.customImageView.layer.borderColor = UIColor(white: 0.9, alpha: 1).cgColor
		self.customImageView.layer.borderWidth = 1
		
		// Create QRCodes

		let helloWorld = "Hello World!"
		
		self.exampleLabel.text = helloWorld
		
		if let qrImage = self.createQRCodeForString(helloWorld) {
			self.normalImageView.image = UIImage(ciImage: qrImage)
		}
		
		if let qrImage = self.createCustomQRCodeForString(helloWorld) {
			self.customImageView.image = qrImage
		}
    }
	
	
	// MARK: - Generate QRCodes
	
	/// Generate a CoreImage image for the text passed in.
	/// This string is converted to ISOLatin1 string encoding, not the usual UTF8.
	/// Then the resulting binary data is past as the input to a CIFilter which makes the QRCode for us
	/// - Parameter text: The text to turn into a QRCode
	func createQRCodeForString(_ text: String, correctionLevel: ErrorCorrectionLevel = ErrorCorrectionLevel.mid) -> CIImage? {
		let data = text.data(using: .isoLatin1)
		
		let qrFilter = CIFilter(name: "CIQRCodeGenerator")
		// Input text
		qrFilter?.setValue(data, forKey: "inputMessage")
		// Error correction
		qrFilter?.setValue(correctionLevel.rawValue, forKey: "inputCorrectionLevel")
		
		return qrFilter?.outputImage
	}
	
	
	
	/// The error correction format.
	/// Check `CIQRCodeGenerator` > `inputCorrectionLevel` for more info.
	/// Higher levels of error correction result in larger output images but allow larger areas of the code to be damaged or obscured without.
	/// There are four possible correction modes (with corresponding error resilience levels):
	enum ErrorCorrectionLevel: String, CaseIterable {
		/// 7%
		case low = "L"
		/// 15%
		case mid = "M"
		/// 25%
		case quality = "Q"
		/// 30%
		case high = "H"
	}
	
	/// Generates a custom QRCode
	/// - Parameters:
	///   - text: The input text for the QRCode
	///   - correctionLevel: The error correction amount to include
	///   - renderingOptions: The custom rendering options to use
	/// - Returns: The QRCode image, if successful
	func createCustomQRCodeForString(_ text: String, correctionLevel: ErrorCorrectionLevel = ErrorCorrectionLevel.mid, renderingOptions: CustomRenderOptions = CustomRenderOptions.defaults) -> UIImage? {
		// Generate the original image
		guard let qrCode:CIImage = self.createQRCodeForString(text, correctionLevel: correctionLevel) else {
			print("Failed to generate QRCode")
			return nil
		}
		
		// Get a pixel grid from the CoreImage QRCode
		guard let pixelGrid: PixelGrid = self.getQRGrid(image: qrCode) else { return nil }
		
		// Render a custom design QRCode from the pixel grid
		return self.renderCustomQRCode(pixelGrid: pixelGrid, options: renderingOptions)
	}
	
	
	
	// MARK: - Turn QRCode into Grid
	
	struct PixelGrid {
		let pixels:[Bool]
		let width:Int
	}
	
	/// Returns a pixel grid from a QRCode image
	/// - Parameter image: The input QRCode image made by `CIQRCodeGenerator`
	/// - Returns: The PixelGrid for that image
	private func getQRGrid(image: CIImage) -> PixelGrid?
	{
		guard let cgImage = self.convertCIImageToCGImage(inputImage: image) else {
			print("Failed to create CGImage")
			return nil
		}
		
		// - Greyscale
		
		guard let (imagePixels, pixelsWidth, pixelsHeight) = self.getGreyScalePixelValues(fromCGImage: cgImage), (pixelsWidth == pixelsHeight) else {
			return nil
		}
		
		var filledPixels:[Bool] = imagePixels.map({
			return ($0 == 0)
		})
		
		
		// - Get ride of corners
		
		// - Remove top right & top left
		for rowIndex in 0..<8 {
			// Top Left Corner
			let indexStartIndex = (rowIndex * pixelsWidth)
			
			for i in (indexStartIndex)..<(indexStartIndex + 8) {
				filledPixels[i] = false
			}
			
			// Top Right Corner
			let rightStartIndex = (indexStartIndex + pixelsWidth) - 8
			
			for i in (rightStartIndex)..<(rightStartIndex + 8) {
				filledPixels[i] = false
			}
		}
		
		// - Bottom Left Grid Corner
		let totalRows = (filledPixels.count / pixelsWidth)
		
		for rowIndex in (totalRows - 8)..<totalRows {
			// Top Left Corner
			let indexStartIndex = (rowIndex * pixelsWidth)
			
			for i in (indexStartIndex)..<(indexStartIndex + 8) {
				filledPixels[i] = false
			}
		}
		//self.printQRCodeGrid(pixels: filledPixels, totalWidth: pixelsWidth)
		
		return PixelGrid(pixels: filledPixels, width: pixelsWidth)
	}
	
	
	// MARK: - Render Custom QRCode
	
	/// Custom rendering options
	struct CustomRenderOptions {
		let cornerRounding:CGFloat
		let centerRounding:CGFloat
		
		let dotRounding:CGFloat
		let dotScale:CGFloat
		
		let drawDebugGrid:Bool
		
		/// Default rendering options
		static var defaults:CustomRenderOptions = CustomRenderOptions(
			cornerRounding: 1,
			centerRounding: 1,
			dotRounding: 1,
			dotScale: 0.78,
			drawDebugGrid: false
		)
	}
	
	/// Take a QRCode grid and render a custom styled QRCode from that
	/// - Parameters:
	///   - pixelGrid: The pixel grid to render
	///   - options: The custom rendering options
	/// - Returns: An QRCode image, if successful
	private func renderCustomQRCode(pixelGrid: PixelGrid, options: CustomRenderOptions = CustomRenderOptions.defaults) -> UIImage?
	{
		// The point size of each grid QRCode pixel
		let scale:CGFloat = 10
		
		let scaledWidth:CGFloat = CGFloat(pixelGrid.width) * scale
		
		let renderSize = CGSize(width: scaledWidth, height: scaledWidth)
		let bounds = CGRect(origin: .zero, size: renderSize)
		
		
		// Graphics Render Settings
		let format = UIGraphicsImageRendererFormat.default()
		format.opaque = true
		format.preferredRange = .standard
		format.scale = 0
		
		let renderer = UIGraphicsImageRenderer(size: renderSize, format: format)
		
		return renderer.image(actions: { (context: UIGraphicsImageRendererContext) in
			// - Background Color
			UIColor.white.setFill()
			context.fill(bounds)
			
			// - Set Colors
			UIColor.black.setFill()
			UIColor.black.setStroke()
			
			/// Helper to draw the QRCode corner blocks repeatedly
			func drawCorner(at startPoint: CGPoint)
			{
				// Corner outer border
				let borderWidth:CGFloat = (6 * scale)
				
				let borderCornerRadius: CGFloat = (borderWidth * 0.5) * options.cornerRounding
				
				let borderPath = UIBezierPath(roundedRect: CGRect(
					x: startPoint.x + (1.5 * scale),
					y: startPoint.y + (1.5 * scale),
					width: borderWidth,
					height: borderWidth
				), cornerRadius: borderCornerRadius)
				
				borderPath.lineCapStyle = .square
				borderPath.lineWidth = scale
				borderPath.stroke()
				
				// Corner center square
				let centerWidth:CGFloat = (3 * scale)
				
				let centerCornerRadius:CGFloat = (centerWidth * 0.5) * options.centerRounding
				
				let centerPath = UIBezierPath(roundedRect: CGRect(
					x: startPoint.x + (3 * scale),
					y: startPoint.y + (3 * scale),
					width: centerWidth,
					height: centerWidth
				), cornerRadius: centerCornerRadius)
				
				centerPath.fill()
			}
			
			// - Top Left Corner
			drawCorner(at: CGPoint.zero)
			
			// Top Right Corner
			drawCorner(at: CGPoint(
				x: renderSize.width - (9 * scale),
				y: 0
			))
			
			// Bottom Left Corner
			drawCorner(at: CGPoint(
				x: 0,
				y: renderSize.height - (9 * scale)
			))
			
			
			// - Draw dots
			let colorAlmostWhite: UIColor = UIColor(white: 0.999, alpha: 1)
			let colorAlmostGrey: UIColor = UIColor(white: 0.9, alpha: 1)
			
			var currentColor: UIColor = colorAlmostWhite
			
			// Debug info
			var text: String = ""
			var lastY: Int = 0
			
			for (pixelIndex, pixel) in pixelGrid.pixels.enumerated() {
				let y: Int = pixelIndex / pixelGrid.width
				let x: Int = pixelIndex - (y * pixelGrid.width)
				
				if y != lastY {
					lastY = y
					text += "\n"
				}
				
				let currentGridRect:CGRect = CGRect(
					x: CGFloat(x) * scale,
					y: CGFloat(y) * scale,
					width: 1 * scale,
					height: 1 * scale
				)
				
				if options.drawDebugGrid
				{
					let centerPath = UIBezierPath(rect: currentGridRect)
					currentColor.setFill()
					centerPath.fill(with: .normal, alpha: 0.25)
					
					if currentColor == colorAlmostWhite {
						currentColor = colorAlmostGrey
					} else {
						currentColor = colorAlmostWhite
					}
				}
				
				
				if pixel
				{
					let dotWidth: CGFloat = (currentGridRect.width * options.dotScale)
					
					let insetX: CGFloat = currentGridRect.origin.x + ((currentGridRect.width - dotWidth) * 0.5)
					let insetY: CGFloat = currentGridRect.origin.y + ((currentGridRect.height - dotWidth) * 0.5)
					
					let dotRect = CGRect(x: insetX, y: insetY, width: dotWidth, height: dotWidth)
					
					let dotCornerRadius: CGFloat = ((dotRect.width * 0.5) * options.dotRounding)
					
					let dotPath = UIBezierPath(roundedRect: dotRect, cornerRadius: dotCornerRadius)
					UIColor.black.setFill()
					dotPath.fill()
				}
				
				text += (pixel ? "1," : "0,")
			}
			
			if options.drawDebugGrid {
				print(text)
			}
		})
	}
	
	
	
	
	
	
	// MARK: - Helpers
	
	private func convertCIImageToCGImage(inputImage: CIImage) -> CGImage? {
		//let context = CIContext(options: nil)
		let context = CIContext(options: [CIContextOption.useSoftwareRenderer: false])
		
		if let cgImage = context.createCGImage(inputImage, from: inputImage.extent) {
			return cgImage
		}
		
		return nil
	}
	
	
	// MARK: - Get Pixels From Grey Scale Image
	
	/// Converts the image to greyscale and gets the pixel values for each pixel in the image
	/// - Parameter imageRef: The CGImage
	/// - Returns: The pixel array, the width of the image, and the height of the image
	private func getGreyScalePixelValues(fromCGImage imageRef: CGImage?) -> (pixelValues: [UInt8], width: Int, height: Int)?
	{
		guard let imageRef = imageRef else { return nil }
		
		let imageWidth: Int = imageRef.width
		let imageHeight: Int = imageRef.height
		let bounds: CGRect = CGRect(x: 0.0, y: 0.0, width: CGFloat(imageWidth), height: CGFloat(imageHeight))
		
		let bitsPerComponent: Int = 8 // imageRef.bitsPerComponent
		let bytesPerRow: Int = 1 * imageWidth // imageRef.bytesPerRow
		let totalBytes: Int = imageHeight * bytesPerRow
		
		let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceGray()
		let bitmapInfo: UInt32 = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue).rawValue
		
		var pixelValues = [UInt8](repeating: 0, count: totalBytes)
		
		let contextRef = CGContext(
			data: &pixelValues,
			width: imageWidth,
			height: imageHeight,
			bitsPerComponent: bitsPerComponent,
			bytesPerRow: bytesPerRow,
			space: colorSpace,
			bitmapInfo: bitmapInfo
		)
		
		contextRef?.draw(imageRef, in: bounds)
		
		return (pixelValues, imageWidth, imageHeight)
	}
	
	
	// MARK: - Print QRCode Grid
	
	private func printQRCodeGrid(pixelGrid: PixelGrid) {
		print("pixelGrid: \(pixelGrid.width)")
		
		var text = ""
		
		var rowIndex:Int = 0
		
		for pixel in pixelGrid.pixels {
			
			if rowIndex >= pixelGrid.width {
				rowIndex = 0
				text += "\n"
			}
			
			text += "\(pixel ? "1" : "0"),"
			
			rowIndex += 1
		}
		
		print(text)
	}
	
}
