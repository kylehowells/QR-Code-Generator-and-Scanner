//
//  UIImage+helpers.swift
//  QR Codes
//
//  Created by Kyle Howells on 01/05/2022.
//  Copyright © 2022 Kyle Howells. All rights reserved.
//

import Foundation
import UIKit
import CoreImage
import CoreGraphics



extension CIImage {
	
	func kh_convertToCGImage() -> CGImage? {
		let inputImage:CIImage = self
		
		//let context = CIContext(options: nil)
		let context = CIContext(options: [CIContextOption.useSoftwareRenderer: false])
		
		if let cgImage: CGImage = context.createCGImage(inputImage, from: inputImage.extent) {
			return cgImage
		}
		
		return nil
	}
	
}



// MARK: - Get Pixels From Grey Scale Image

extension CGImage {
	
	/// Converts the image to greyscale and gets the pixel values for each pixel in the image
	/// - Returns: The pixel array, the width of the image, and the height of the image
	func kh_getGreyScalePixelValues() -> (pixelValues: [UInt8], width: Int, height: Int)?
	{
		let inputImageRef:CGImage = self
		
		let imageWidth: Int = inputImageRef.width
		let imageHeight: Int = inputImageRef.height
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
		
		contextRef?.draw(inputImageRef, in: bounds)
		
		return (pixelValues, imageWidth, imageHeight)
	}

}
