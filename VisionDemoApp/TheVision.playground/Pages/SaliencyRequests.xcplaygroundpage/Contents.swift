//: [Previous](@previous)

import UIKit
import Vision


import Foundation

struct ImageProcessor {
    func process(_ image: UIImage, isObjectness: Bool) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        let saliencyRequest = isObjectness ? VNGenerateObjectnessBasedSaliencyImageRequest() : VNGenerateAttentionBasedSaliencyImageRequest()
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage,
                                                   orientation: .init(image.imageOrientation),
                                                   options: [:])

        // Remove separate quque to make results more streamlined
            do {
                try requestHandler.perform([saliencyRequest])
            } catch {
                print("Can't make the request due to \(error)")
            }

            guard let results = saliencyRequest.results as? [VNSaliencyImageObservation] else { return nil }
            
            let rectangles = results
                .flatMap { $0.salientObjects?.map { $0.boundingBox.rectangle(in: image) } ?? [] }
                .map { CGRect(origin: $0.origin.translateFromCoreImageToUIKitCoordinateSpace(using: image.size.height - $0.size.height),
                              size: $0.size) }
            
            let heatMap = results.first?.pixelBuffer.makeImage()
            
        return image.draw(rectangles: rectangles,
                          image: heatMap)
    }
}

extension UIImage {
    func draw(rectangles: [CGRect],
              image: UIImage?,
              strokeColor: UIColor = .primary,
              lineWidth: CGFloat = 4) -> UIImage? {
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

let imageProcessor = ImageProcessor()

let cupcake = UIImage(named: "cupcake.jpg")!
let objectnessCupcake = imageProcessor.process(cupcake, isObjectness: true)
let attentionCupcake = imageProcessor.process(cupcake, isObjectness: false)

let car = UIImage(named: "car.jpg")!
let objectnessCar = imageProcessor.process(car, isObjectness: true)
let attentionCar = imageProcessor.process(car, isObjectness: false)

let lake = UIImage(named: "lake.jpg")!
let objectnessLake = imageProcessor.process(lake, isObjectness: true)
let attentionLake = imageProcessor.process(lake, isObjectness: false)
//: [Next](@next)
