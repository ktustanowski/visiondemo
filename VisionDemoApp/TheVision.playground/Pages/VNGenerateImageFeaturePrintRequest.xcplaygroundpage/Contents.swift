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

let balloon1 = UIImage(named: "balloon_1.jpg")!
let balloon1FeaturePrint = process(balloon1)!

let balloon2 = UIImage(named: "balloon_2.jpg")!
let balloon2FeaturePrint = process(balloon2)!

let balloon3 = UIImage(named: "balloon_3.jpg")!
let balloon3FeaturePrint = process(balloon3)!

let balloon4 = UIImage(named: "balloon_4.jpg")!
let balloon4FeaturePrint = process(balloon4)!

let heart = UIImage(named: "heart.jpg")!
let heartFeaturePrint = process(heart)!

let plane = UIImage(named: "plane.jpg")! // Original photo by https://unsplash.com/@nbb_photos
let planeFeaturePrint = process(plane)!

var balloon1ToBallon2Distance: Float = .infinity
var balloon1ToBallon3Distance: Float = .infinity
var balloon1ToBallon4Distance: Float = .infinity
var balloon1ToHeartDistance: Float = .infinity
var balloon1ToPlaneDistance: Float = .infinity

do {
    try balloon1FeaturePrint.computeDistance(&balloon1ToBallon2Distance, to: balloon2FeaturePrint)
    try balloon1FeaturePrint.computeDistance(&balloon1ToBallon3Distance, to: balloon3FeaturePrint)
    try balloon1FeaturePrint.computeDistance(&balloon1ToBallon4Distance, to: balloon4FeaturePrint)
    try balloon1FeaturePrint.computeDistance(&balloon1ToHeartDistance, to: heartFeaturePrint)
    try balloon1FeaturePrint.computeDistance(&balloon1ToPlaneDistance, to: planeFeaturePrint)
} catch {
    print("Couldn't compute the distance")
}

// Tap on rectangular icons on the right to see values and images.
// If two images won't fit make sure you make the component larger.

[balloon1, balloon2]
balloon1ToBallon2Distance
[balloon1, balloon3]
balloon1ToBallon3Distance
[balloon1, balloon4]
balloon1ToBallon4Distance
[balloon1, heart]
balloon1ToHeartDistance

[balloon1, plane]
balloon1ToPlaneDistance

//: [Next](@next)
