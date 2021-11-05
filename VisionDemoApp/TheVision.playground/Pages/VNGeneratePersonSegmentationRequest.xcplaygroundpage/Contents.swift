//: [Previous](@previous)

var readThisFirst = "⚠️ Playgrounds are dependent on the project so you need to build the project first before using them."

import UIKit
import Vision

func process(_ image: UIImage) -> UIImage? {
    guard let cgImage = image.cgImage else { return nil }
    let segmentationRequest = VNGeneratePersonSegmentationRequest()
    segmentationRequest.qualityLevel = .accurate
    segmentationRequest.outputPixelFormat = kCVPixelFormatType_OneComponent32Float
    
    let requestHandler = VNImageRequestHandler(cgImage: cgImage,
                                               orientation: .init(image.imageOrientation),
                                               options: [:])
    do {
        try requestHandler.perform([segmentationRequest])
    } catch {
        print("Can't make the request due to \(error)")
    }
    
    guard let results = segmentationRequest.results else { return nil }
    
    let heatMap = results.first?.pixelBuffer.makeImage()
    
    return image.draw(image: heatMap)
}

extension UIImage {
    func draw(image: UIImage?) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            draw(in: CGRect(origin: .zero, size: size))
            
            image?.draw(in: CGRect(origin: .zero, size: size), blendMode: .hue, alpha: 1.0)
        }
    }
}

let beach = UIImage(named: "beach.jpg")! // Original photo by https://unsplash.com/@omarlopez1
process(beach)

let mountains = UIImage(named: "mountains.jpg")! // Original photo by https://unsplash.com/@thoughtcatalog
process(mountains)

//: [Next](@next)
