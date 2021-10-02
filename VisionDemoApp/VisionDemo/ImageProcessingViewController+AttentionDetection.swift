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
        let attentionRequest = VNGenerateAttentionBasedSaliencyImageRequest()
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage,
                                                   orientation: .init(image.imageOrientation),
                                                   options: [:])

        saveImageButton.isHidden = false
        visionQueue.async { [weak self] in
            do {
                try requestHandler.perform([attentionRequest])
            } catch {
                print("Can't make the request due to \(error)")
            }

            guard let results = attentionRequest.results else { return }
            
            let rectangles = results
                .compactMap { $0.salientObjects?.map { $0.boundingBox.rectangle(in: image) } }
                .flatMap { $0 }
                .map { CGRect(origin: $0.origin.translateFromCoreImageToUIKitCoordinateSpace(using: image.size.height - $0.size.height),
                              size: $0.size) }
            
            let heatmapImages = results.compactMap { $0.pixelBuffer.makeImage() }
            
            DispatchQueue.main.async {
                self?.imageView.image = image.draw(rectangles: rectangles,
                                                   images: heatmapImages)
            }
        }
    }
}

extension UIImage {
    func draw(rectangles: [CGRect],
              images: [UIImage],
              strokeColor: UIColor = .primary,
              lineWidth: CGFloat = 2) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            draw(in: CGRect(origin: .zero, size: size))
            
            images.forEach { $0.draw(in: CGRect(origin: .zero, size: size), blendMode: .hue, alpha: 1.0) }
            
            context.cgContext.setStrokeColor(strokeColor.cgColor)
            context.cgContext.setLineWidth(lineWidth)
            rectangles.forEach { context.cgContext.addRect($0) }
            context.cgContext.drawPath(using: .stroke)
        }
    }
}
