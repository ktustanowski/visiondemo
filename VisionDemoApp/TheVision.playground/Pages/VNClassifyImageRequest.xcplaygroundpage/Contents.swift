//: [Previous](@previous)

import UIKit
import Vision

struct ImageProcessor {
    func process(_ image: UIImage) -> [String] {
        guard let cgImage = image.cgImage else { return [] }
        let request = VNClassifyImageRequest()
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage,
                                                   orientation: .init(image.imageOrientation),
                                                   options: [:])
        do {
            try requestHandler.perform([request])
        } catch {
            print("Can't make the request due to \(error)")
        }
        
        guard let results = request.results as? [VNClassificationObservation] else { return [] }
        
        return results
            .filter { $0.confidence > 0.7 }
            .map { "\($0.identifier) - \((Int($0.confidence * 100)))%" }
    }
}

let imageProcessor = ImageProcessor()

let cupcake = UIImage(named: "cupcake.jpg")! // Original photo by https://unsplash.com/@ibrahimboran
let cupcakeIdentifiers = imageProcessor.process(cupcake)

let plane = UIImage(named: "plane.jpg")! // Original photo by https://unsplash.com/@nbb_photos
let planeIdentifiers = imageProcessor.process(plane)

let lake = UIImage(named: "lake.jpg")! // Original photo by https://unsplash.com/@u2b_photos
let lakeIdentifiers = imageProcessor.process(lake)

//: [Next](@next)
