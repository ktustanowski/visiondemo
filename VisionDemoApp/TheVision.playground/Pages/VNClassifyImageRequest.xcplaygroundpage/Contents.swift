//: [Previous](@previous)
var readThisFirst = "⚠️ Playgrounds are dependent on the project so you need to build the project first before using them."
var readThisSecond = "⚠️ If you are using M1 and run Xcode using Rosetta playgrounds won't work https://twitter.com/kwcodes/status/1451275902772461571"

import UIKit
import Vision

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

let cupcake = UIImage(named: "cupcake.jpg")! // Original photo by https://unsplash.com/@ibrahimboran
process(cupcake)

let plane = UIImage(named: "plane.jpg")! // Original photo by https://unsplash.com/@nbb_photos
process(plane)

let lake = UIImage(named: "lake.jpg")! // Original photo by https://unsplash.com/@u2b_photos
process(lake)

//: [Next](@next)
