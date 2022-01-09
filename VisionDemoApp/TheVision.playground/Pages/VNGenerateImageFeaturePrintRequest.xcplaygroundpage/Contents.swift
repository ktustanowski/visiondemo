//: [Previous](@previous)
var readThisFirst = "⚠️ Playgrounds are dependent on the project so you need to build the project first before using them."
var readThisSecond = "⚠️ If you are using M1 and run Xcode using Rosetta playgrounds won't work https://twitter.com/kwcodes/status/1451275902772461571"
var readThisThird = "⚠️ Not each request seems to work properly in the plaugrounds or simulator. All playgrounds I provide contain code that is working for me but if you experience issues just take the code and use in the application on actual device."

import UIKit
import Vision

func process(_ image: UIImage) -> VNFeaturePrintObservation? {
    guard let cgImage = image.cgImage else { return nil }
    let request = VNGenerateImageFeaturePrintRequest()
    
    let requestHandler = VNImageRequestHandler(cgImage: cgImage,
                                               orientation: .init(image.imageOrientation),
                                               options: [:])
    do {
        try requestHandler.perform([request])
    } catch {
        print("Can't make the request due to \(error)")
    }
    
    guard let result = request.results?.first else { return nil }
    return result
}

let baloon1 = UIImage(named: "baloon_1.jpg")!
let baloon1FeaturePrint = process(baloon1)!

let baloon2 = UIImage(named: "baloon_2.jpg")!
let baloon2FeaturePrint = process(baloon2)!

let baloon3 = UIImage(named: "baloon_3.jpg")!
let baloon3FeaturePrint = process(baloon3)!

let baloon4 = UIImage(named: "baloon_4.jpg")!
let baloon4FeaturePrint = process(baloon4)!

let heart = UIImage(named: "heart.jpg")!
let heartFeaturePrint = process(heart)!

let plane = UIImage(named: "plane.jpg")! // Original photo by https://unsplash.com/@nbb_photos
let planeFeaturePrint = process(plane)!

var baloon1ToBallon2Distance: Float = .infinity
var baloon1ToBallon3Distance: Float = .infinity
var baloon1ToBallon4Distance: Float = .infinity
var baloon1ToHeartDistance: Float = .infinity
var baloon1ToPlaneDistance: Float = .infinity

do {
    try baloon1FeaturePrint.computeDistance(&baloon1ToBallon2Distance, to: baloon2FeaturePrint)
    try baloon1FeaturePrint.computeDistance(&baloon1ToBallon3Distance, to: baloon3FeaturePrint)
    try baloon1FeaturePrint.computeDistance(&baloon1ToBallon4Distance, to: baloon4FeaturePrint)
    try baloon1FeaturePrint.computeDistance(&baloon1ToHeartDistance, to: heartFeaturePrint)
    try baloon1FeaturePrint.computeDistance(&baloon1ToPlaneDistance, to: planeFeaturePrint)
} catch {
    print("Couldn't compute the distance")
}

// Tap on rectangular icons on the right to see values and images.
// If two images won't fit make sure you make the component larger.

[baloon1, baloon2]
baloon1ToBallon2Distance
[baloon1, baloon3]
baloon1ToBallon3Distance
[baloon1, baloon4]
baloon1ToBallon4Distance
[baloon1, heart]
baloon1ToHeartDistance

[baloon1, plane]
baloon1ToPlaneDistance

//: [Next](@next)
