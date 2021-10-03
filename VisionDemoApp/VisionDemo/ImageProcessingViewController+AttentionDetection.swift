//
//  ImageProcessingViewController+AnimalsDetection.swift
//  VisionDemo
//
//  Created by Kamil Tustanowski on 16/09/2021.
//

import UIKit
import Vision

extension ImageProcessingViewController {
    func process(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        let saliencyRequest = VNGenerateObjectnessBasedSaliencyImageRequest()
//        let saliencyRequest = VNGenerateAttentionBasedSaliencyImageRequest()
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage,
                                                   orientation: .init(image.imageOrientation),
                                                   options: [:])

        saveImageButton.isHidden = false
        visionQueue.async { [weak self] in
            do {
                try requestHandler.perform([saliencyRequest])
            } catch {
                print("Can't make the request due to \(error)")
            }

            guard let results = saliencyRequest.results as? [VNSaliencyImageObservation] else { return }
            
            let rectangles = results
                .flatMap { $0.salientObjects?.map { $0.boundingBox.rectangle(in: image) } ?? [] }
                .map { CGRect(origin: $0.origin.translateFromCoreImageToUIKitCoordinateSpace(using: image.size.height - $0.size.height),
                              size: $0.size) }
            
            let heatMap = results.first?.pixelBuffer.makeImage()
            
            DispatchQueue.main.async {
                self?.imageView.image = image.draw(rectangles: rectangles,
                                                   image: heatMap)
            }
        }
    }
}

extension UIImage {
    func draw(rectangles: [CGRect],
              image: UIImage?,
              strokeColor: UIColor = .primary,
              lineWidth: CGFloat = 2) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            draw(in: CGRect(origin: .zero, size: size))
            
            image?.draw(in: CGRect(origin: .zero, size: size), blendMode: .hue, alpha: 1.0)
            
            context.cgContext.setStrokeColor(strokeColor.cgColor)
            context.cgContext.setLineWidth(lineWidth)
            rectangles.forEach { context.cgContext.addRect($0) }
            context.cgContext.drawPath(using: .stroke)
        }
    }
}
