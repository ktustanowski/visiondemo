//: [Previous](@previous)
var readThisFirst = "⚠️ Playgrounds are dependent on the project so you need to build the project first before using them."
var readThisSecond = "⚠️ If you are using M1 and run Xcode using Rosetta playgrounds won't work https://twitter.com/kwcodes/status/1451275902772461571"

import UIKit
import Vision

func process(_ image: UIImage, isObjectness: Bool) -> UIImage? {
    guard let cgImage = image.cgImage else { return nil }
    let saliencyRequest = isObjectness ? VNGenerateObjectnessBasedSaliencyImageRequest() : VNGenerateAttentionBasedSaliencyImageRequest()
    
    let requestHandler = VNImageRequestHandler(cgImage: cgImage,
                                               orientation: .init(image.imageOrientation),
                                               options: [:])
    
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

extension UIImage {
    func draw(rectangles: [CGRect],
              image: UIImage?,
              strokeColor: UIColor = .primary,
              lineWidth: CGFloat = 20) -> UIImage? {
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

let cupcake = UIImage(named: "cupcake.jpg")! // Original photo by https://unsplash.com/@ibrahimboran
process(cupcake, isObjectness: true)
process(cupcake, isObjectness: false)

let plane = UIImage(named: "plane.jpg")! // Original photo by https://unsplash.com/@nbb_photos
process(plane, isObjectness: true)
process(plane, isObjectness: false)

let lake = UIImage(named: "lake.jpg")! // Original photo by https://unsplash.com/@u2b_photos
process(lake, isObjectness: true)
process(lake, isObjectness: false)
//: [Next](@next)
